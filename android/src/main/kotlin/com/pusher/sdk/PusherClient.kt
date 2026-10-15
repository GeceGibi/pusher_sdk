package com.pusher.sdk

import android.content.Context
import org.json.JSONObject
import java.io.BufferedReader
import java.io.IOException
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.util.Locale
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/// Native signed HTTP client for hello and notification receipts.
///
/// A request that fails on the network, with 408, 429 or 5xx, is saved to a disk
/// queue and retried with backoff for up to 48 hours. Other 4xx answers are final.
object PusherClient {
  const val STATUS_DELIVERED = 1
  const val STATUS_OPENED = 2

  private val retryDelaysSeconds = longArrayOf(30, 120, 600, 1800, 3600)

  private class HttpFailure(val code: Int, message: String) : IOException(message)

  private val executor = Executors.newSingleThreadScheduledExecutor()

  /// Touched only on [executor].
  private var attempt = 0
  private var retryScheduled = false

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

    if (isEmulator != null &&
      debugMode != null &&
      !appVersionCode.isNullOrBlank() &&
      !osVersion.isNullOrBlank() &&
      !appVersion.isNullOrBlank() &&
      !brand.isNullOrBlank() &&
      !model.isNullOrBlank()
    ) {
      PusherConfig.saveDeviceFields(
        context,
        PusherDeviceFields(
          isEmulator = isEmulator,
          debugMode = debugMode,
          appVersionCode = appVersionCode.trim(),
          osVersion = osVersion.trim(),
          appVersion = appVersion.trim(),
          brand = brand.trim(),
          model = model.trim(),
        ),
      )
    }

    val item = PusherPending(
      kind = PusherPending.KIND_HELLO,
      token = token?.trim()?.takeIf { it.isNotEmpty() },
      locale = locale?.trim()?.takeIf { it.isNotEmpty() },
    )
    submit(context, item)
  }

  /// Sends everything waiting in the retry queue.
  fun flushPending(context: Context) {
    val app = context.applicationContext
    executor.execute { flush(app) }
  }

  /// Posts one receipt when [nid] is present. [onDone] always fires once.
  fun receipt(context: Context, nid: String, status: Int, onDone: (() -> Unit)? = null) {
    val trimmed = nid.trim()

    if (trimmed.isEmpty() || (status != STATUS_DELIVERED && status != STATUS_OPENED)) {
      PusherLog.w("receipt skip: nid='$trimmed' status=$status")
      onDone?.invoke()
      return
    }

    val item = PusherPending(PusherPending.KIND_RECEIPT, nid = trimmed, status = status)

    if (!PusherConfig.isReady(context)) {
      PusherLog.w("receipt queued: config not ready nid=$trimmed")
      PusherConfig.enqueuePending(context, item)
      onDone?.invoke()
      return
    }

    submit(context, item, onDone)
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

  private fun submit(context: Context, item: PusherPending, onDone: (() -> Unit)? = null) {
    val app = context.applicationContext
    executor.execute {
      try {
        if (send(app, item)) flush(app)
      } finally {
        onDone?.invoke()
      }
    }
  }

  /// Sends the queue in order. Stops at the first retryable failure.
  private fun flush(app: Context) {
    val items = PusherConfig.drainPending(app)
    if (items.isEmpty()) return
    PusherLog.d("flushing ${items.size} pending")

    for ((index, item) in items.withIndex()) {
      if (!send(app, item)) {
        items.drop(index + 1).forEach { PusherConfig.enqueuePending(app, it) }
        return
      }
    }
  }

  /// True when the item is done (sent or rejected for good). False when queued for retry.
  private fun send(app: Context, item: PusherPending): Boolean {
    try {
      post(app, item)
      attempt = 0
      return true
    } catch (error: HttpFailure) {
      val retryable = error.code == 408 || error.code == 429 || error.code >= 500
      PusherLog.e("${item.kind} failed: ${error.message}", error)
      if (!retryable) return true
    } catch (error: Exception) {
      PusherLog.e("${item.kind} failed: ${error.message}", error)
    }

    PusherConfig.enqueuePending(app, item)
    scheduleRetry(app)
    return false
  }

  private fun scheduleRetry(app: Context) {
    if (retryScheduled) return
    retryScheduled = true
    val delay = retryDelaysSeconds[minOf(attempt, retryDelaysSeconds.lastIndex)]
    attempt++
    PusherLog.d("retry in ${delay}s")
    executor.schedule({
      retryScheduled = false
      flush(app)
    }, delay, TimeUnit.SECONDS)
  }

  private fun post(context: Context, item: PusherPending) {
    val projectId = PusherConfig.projectId(context)
      ?: throw IllegalStateException("projectId is null")
    val statsKey = PusherConfig.statsKey(context)
      ?: throw IllegalStateException("statsKey is null")

    val fields = PusherConfig.deviceFields(context)
    val body = JSONObject()
      .put("clientId", PusherConfig.resolveDeviceId(context))
      .put("platform", "android")
      .put("locale", item.locale ?: Locale.getDefault().toString())
      .put("isEmulator", fields.isEmulator)
      .put("debugMode", fields.debugMode)
      .put("appVersionCode", fields.appVersionCode)
      .put("sdkVersion", PusherConfig.SDK_VERSION)
      .put("osVersion", fields.osVersion)
      .put("appVersion", fields.appVersion)
      .put("brand", fields.brand)
      .put("model", fields.model)

    val path = if (item.kind == PusherPending.KIND_HELLO) {
      item.token?.let { body.put("token", it) }
      "/$projectId/hi"
    } else {
      body.put("status", item.status)
      "/$projectId/n/${item.nid}"
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
      OutputStreamWriter(connection.outputStream, Charsets.UTF_8).use { it.write(raw) }

      val code = connection.responseCode
      val responseBody = readBody(connection, code)
      PusherLog.d("POST response path=$path http=$code body=$responseBody")
      if (code !in 200..299) {
        throw HttpFailure(code, "HTTP $code: $responseBody")
      }
    } finally {
      connection.disconnect()
    }
  }

  private fun readBody(connection: HttpURLConnection, code: Int): String {
    val stream = if (code >= 400) connection.errorStream else connection.inputStream
    return stream?.let {
      BufferedReader(InputStreamReader(it, Charsets.UTF_8)).use { reader -> reader.readText() }
    }.orEmpty()
  }
}
