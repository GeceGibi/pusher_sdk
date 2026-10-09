package com.pusher.pusher_sdk

import android.content.Context
import android.util.Log
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.util.Locale
import java.util.concurrent.Executors

/// Native signed HTTP client for hello and notification receipts.
object PusherClient {
  const val STATUS_DELIVERED = 1
  const val STATUS_OPENED = 2

  private const val TAG = "PusherSdk"
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
  ) {
    if (!PusherConfig.isReady(context)) {
      return
    }

    if (appVersionCode.isNullOrBlank() || isEmulator == null || debugMode == null) {
      return
    }

    val projectId = PusherConfig.projectId(context) ?: return
    val deviceId = PusherConfig.resolveDeviceId(context)
    val body = JSONObject()
    body.put("device_id", deviceId)
    body.put("platform", "android")
    body.put("locale", locale?.takeIf { it.isNotBlank() } ?: Locale.getDefault().toString())
    body.put("is_emulator", isEmulator)
    body.put("debug_mode", debugMode)
    body.put("app_version_code", appVersionCode)
    putOptional(body, "token", token)
    putOptional(body, "os_version", osVersion)
    putOptional(body, "app_version", appVersion)

    postAsync(context, "/$projectId/hi", body)
  }

  /// Posts one receipt when [nid] is present. [onDone] always fires once.
  fun receipt(context: Context, nid: String, status: Int, onDone: (() -> Unit)? = null) {
    val trimmed = nid.trim()
    val projectId = PusherConfig.projectId(context)
    val valid = trimmed.isNotEmpty() &&
      (status == STATUS_DELIVERED || status == STATUS_OPENED) &&
      PusherConfig.isReady(context) &&
      projectId != null

    if (!valid) {
      onDone?.invoke()
      return
    }

    val deviceId = PusherConfig.resolveDeviceId(context)
    val body = JSONObject()
    body.put("device_id", deviceId)
    body.put("platform", "android")
    body.put("status", status)
    body.put("locale", Locale.getDefault().toString())

    postAsync(context, "/$projectId/n/$trimmed", body, onDone)
  }

  /// Delivered receipt from FCM data map when `nid` is set.
  fun receiptFromData(
    context: Context,
    data: Map<String, String>,
    status: Int,
    onDone: (() -> Unit)? = null,
  ) {
    receipt(context, data["nid"].orEmpty(), status, onDone)
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
  ) {
    val appContext = context.applicationContext
    executor.execute {
      try {
        post(appContext, path, body)
      } catch (error: Exception) {
        Log.w(TAG, "POST $path failed: ${error.message}")
      } finally {
        onDone?.invoke()
      }
    }
  }

  private fun post(context: Context, path: String, body: JSONObject) {
    val statsKey = PusherConfig.statsKey(context) ?: return
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
      if (code < 200 || code >= 300) {
        Log.w(TAG, "HTTP $code for $path")
      }
    } finally {
      connection.disconnect()
    }
  }
}
