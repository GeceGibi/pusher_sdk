package com.pusher.sdk

import android.content.Context
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.util.Locale
import java.util.concurrent.Executors

/// Native signed HTTP client for hello and notification receipts.
object PusherClient {
  const val STATUS_DELIVERED = 1
  const val STATUS_OPENED = 2

  private val executor = Executors.newSingleThreadExecutor()

  /// Posts device hello. Optional fields come from Flutter [device_helpers].
  fun hello(
    context: Context,
    token: String? = null,
    locale: String? = null,
    isEmulator: Boolean? = null,
    debugMode: Boolean? = null,
    appVersionCode: String? = null,
    osVersion: String? = null,
    appVersion: String? = null,
    brand: String? = null,
    model: String? = null,
  ) {
    if (!PusherConfig.isReady(context)) {
      PusherLog.w("hello skip: config not ready")
      return
    }

    if (appVersionCode.isNullOrBlank() ||
      isEmulator == null ||
      debugMode == null ||
      osVersion.isNullOrBlank() ||
      appVersion.isNullOrBlank() ||
      brand.isNullOrBlank() ||
      model.isNullOrBlank()
    ) {
      PusherLog.w("hello skip: missing required device fields")
      return
    }

    val fields = PusherDeviceFields(
      isEmulator = isEmulator,
      debugMode = debugMode,
      appVersionCode = appVersionCode.trim(),
      osVersion = osVersion.trim(),
      appVersion = appVersion.trim(),
      brand = brand.trim(),
      model = model.trim(),
    )
    PusherConfig.saveDeviceFields(context, fields)

    val projectId = PusherConfig.projectId(context) ?: return
    val deviceId = PusherConfig.resolveDeviceId(context)
    val body = JSONObject()
    body.put("clientId", deviceId)
    body.put("platform", "android")
    body.put("locale", locale?.takeIf { it.isNotBlank() } ?: Locale.getDefault().toString())
    body.put("isEmulator", fields.isEmulator)
    body.put("debugMode", fields.debugMode)
    body.put("appVersionCode", fields.appVersionCode)
    body.put("sdkVersion", PusherConfig.SDK_VERSION)
    body.put("osVersion", fields.osVersion)
    body.put("appVersion", fields.appVersion)
    body.put("brand", fields.brand)
    body.put("model", fields.model)
    putOptional(body, "token", token)

    PusherLog.d("hello enqueue deviceId=$deviceId projectId=$projectId")
    postAsync(context, "/$projectId/hi", body) {
      flushPendingReceipts(context)
    }
  }

  /// Flushes any pending receipts queued from offline or failed previous attempts.
  fun flushPendingReceipts(context: Context) {
    val pending = PusherConfig.drainPendingReceipts(context)
    if (pending.isEmpty()) return
    PusherLog.d("flushing ${pending.size} pending receipts")
    for ((nid, status) in pending) {
      receipt(context, nid, status)
    }
  }

  /// Posts one receipt when [nid] is present. [onDone] always fires once.
  fun receipt(context: Context, nid: String, status: Int, onDone: (() -> Unit)? = null) {
    val trimmed = nid.trim()
    val projectId = PusherConfig.projectId(context)
    val ready = PusherConfig.isReady(context)
    val valid = trimmed.isNotEmpty() &&
      (status == STATUS_DELIVERED || status == STATUS_OPENED) &&
      ready &&
      projectId != null

    if (!valid) {
      PusherLog.w(
        "receipt skip: nid='$trimmed' status=$status ready=$ready projectId=$projectId",
      )
      if (trimmed.isNotEmpty() && (status == STATUS_DELIVERED || status == STATUS_OPENED)) {
        PusherConfig.enqueuePendingReceipt(context, trimmed, status)
      }
      onDone?.invoke()
      return
    }

    val fields = PusherConfig.deviceFields(context)
    val deviceId = PusherConfig.resolveDeviceId(context)
    val body = JSONObject()
    body.put("clientId", deviceId)
    body.put("platform", "android")
    body.put("status", status)
    body.put("locale", Locale.getDefault().toString())
    body.put("isEmulator", fields.isEmulator)
    body.put("debugMode", fields.debugMode)
    body.put("appVersionCode", fields.appVersionCode)
    body.put("sdkVersion", PusherConfig.SDK_VERSION)
    body.put("osVersion", fields.osVersion)
    body.put("appVersion", fields.appVersion)
    body.put("brand", fields.brand)
    body.put("model", fields.model)

    PusherLog.d("receipt enqueue nid=$trimmed status=$status deviceId=$deviceId")
    postAsync(context, "/$projectId/n/$trimmed", body, onDone, onError = {
      PusherConfig.enqueuePendingReceipt(context, trimmed, status)
    })
  }

  /// Delivered receipt from FCM data map when `nid` is set.
  fun receiptFromData(
    context: Context,
    data: Map<String, String>,
    status: Int,
    onDone: (() -> Unit)? = null,
  ) {
    val nid = data["nid"].orEmpty()
    PusherLog.d("receiptFromData nid=$nid status=$status keys=${data.keys}")
    receipt(context, nid, status, onDone)
  }

  private fun putOptional(body: JSONObject, key: String, value: String?) {
    val trimmed = value?.trim()
    if (!trimmed.isNullOrEmpty()) {
      body.put(key, trimmed)
    }
  }

  private fun postAsync(
    context: Context,
    path: String,
    body: JSONObject,
    onDone: (() -> Unit)? = null,
    onError: (() -> Unit)? = null,
  ) {
    val appContext = context.applicationContext
    executor.execute {
      var success = false
      try {
        post(appContext, path, body)
        success = true
      } catch (error: Exception) {
        PusherLog.e("POST $path failed: ${error.message}", error)
        onError?.invoke()
      } finally {
        onDone?.invoke()
      }
    }
  }

  private fun post(context: Context, path: String, body: JSONObject) {
    val statsKey = PusherConfig.statsKey(context)
    if (statsKey == null) {
      PusherLog.w("POST $path skip: statsKey null")
      throw IllegalStateException("statsKey is null")
    }

    val raw = body.toString()
    val timestamp = System.currentTimeMillis() / 1000L
    val signature = PusherHmac.signature(
      method = "POST",
      pathAndQuery = path,
      unixSeconds = timestamp,
      body = raw,
      key = statsKey,
    )

    val url = URL("${PusherConfig.baseUrl()}/v1$path")
    PusherLog.d("POST start $url body=$raw")

    val connection = (url.openConnection() as HttpURLConnection).apply {
      requestMethod = "POST"
      connectTimeout = 15_000
      readTimeout = 15_000
      doOutput = true
      setRequestProperty("content-type", "application/json")
      setRequestProperty("x-timestamp", timestamp.toString())
      setRequestProperty("x-signature", signature)
    }

    try {
      OutputStreamWriter(connection.outputStream, Charsets.UTF_8).use { writer ->
        writer.write(raw)
      }

      val code = connection.responseCode
      val responseBody = readBody(connection)
      PusherLog.d("POST response path=$path http=$code body=$responseBody")
      if (code !in 200..299) {
        throw java.io.IOException("HTTP $code: $responseBody")
      }
    } finally {
      connection.disconnect()
    }
  }

  private fun readBody(connection: HttpURLConnection): String {
    val stream = if (connection.responseCode >= 400) {
      connection.errorStream
    } else {
      connection.inputStream
    }

    if (stream == null) {
      return ""
    }

    return BufferedReader(InputStreamReader(stream, Charsets.UTF_8)).use { reader ->
      reader.readText()
    }
  }
}
