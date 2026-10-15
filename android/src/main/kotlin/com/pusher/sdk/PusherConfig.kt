package com.pusher.sdk

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

/// Device fields required on every stats receipt (and hello).
internal data class PusherDeviceFields(
  val isEmulator: Boolean,
  val debugMode: Boolean,
  val appVersionCode: String,
  val osVersion: String,
  val appVersion: String,
  val brand: String,
  val model: String,
)

/// A hello or receipt waiting to be re-sent. [at] is when it was first queued.
internal data class PusherPending(
  val kind: String,
  val nid: String? = null,
  val status: Int = 0,
  val token: String? = null,
  val locale: String? = null,
  val at: Long = System.currentTimeMillis(),
) {
  /// Hello entries collapse to one. Receipts are unique per nid and status.
  fun sameAs(other: PusherPending): Boolean {
    if (kind != other.kind) return false
    return kind == KIND_HELLO || (nid == other.nid && status == other.status)
  }

  fun toJson(): JSONObject = JSONObject()
    .put("kind", kind)
    .put("nid", nid)
    .put("status", status)
    .put("token", token)
    .put("locale", locale)
    .put("at", at)

  companion object {
    const val KIND_HELLO = "hello"
    const val KIND_RECEIPT = "receipt"

    fun fromJson(json: JSONObject) = PusherPending(
      kind = json.getString("kind"),
      nid = json.optString("nid").takeIf { it.isNotEmpty() && it != "null" },
      status = json.optInt("status"),
      token = json.optString("token").takeIf { it.isNotEmpty() && it != "null" },
      locale = json.optString("locale").takeIf { it.isNotEmpty() && it != "null" },
      at = json.optLong("at"),
    )
  }
}

/// Persists project keys, install id, and last known device fields.
internal object PusherConfig {
  private const val PREFS = "pusher"
  const val PROJECT_ID = "pusher.project_id"
  const val STATS_KEY = "pusher.stats_key"
  const val DEVICE_ID = "pusher.device_id"
  const val IS_EMULATOR = "pusher.is_emulator"
  const val DEBUG_MODE = "pusher.debug_mode"
  const val APP_VERSION_CODE = "pusher.app_version_code"
  const val OS_VERSION = "pusher.os_version"
  const val APP_VERSION = "pusher.app_version"
  const val BRAND = "pusher.brand"
  const val MODEL = "pusher.model"
  const val ENABLE_LOGS = "pusher.enable_logs"
  const val PENDING_QUEUE = "pusher.pending_queue"
  const val MAX_PENDING = 200
  const val PENDING_MAX_AGE_MS = 48L * 60 * 60 * 1000
  const val DEFAULT_BASE_URL = "https://stats.pusher.tr"

  /// Sourced from build.gradle.kts via BuildConfig.
  val SDK_VERSION: String get() = BuildConfig.SDK_VERSION

  fun prefs(context: Context): SharedPreferences {
    return context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
  }

  /// Stores [projectId] and [statsKey] only.
  fun save(
    context: Context,
    projectId: String,
    statsKey: String,
  ) {
    prefs(context)
      .edit()
      .putString(PROJECT_ID, projectId)
      .putString(STATS_KEY, statsKey)
      .apply()
  }

  /// Persists and applies non-error logging for native + receivers.
  fun setEnableLogs(context: Context, enabled: Boolean) {
    prefs(context).edit().putBoolean(ENABLE_LOGS, enabled).apply()
    PusherLog.enabled = enabled
  }

  /// Restores [PusherLog.enabled] from prefs (cold receiver / process restart).
  fun syncLogging(context: Context) {
    PusherLog.enabled = prefs(context).getBoolean(ENABLE_LOGS, false)
  }

  /// Persists device fields from hello so background receipts can reuse them.
  fun saveDeviceFields(context: Context, fields: PusherDeviceFields) {
    prefs(context)
      .edit()
      .putBoolean(IS_EMULATOR, fields.isEmulator)
      .putBoolean(DEBUG_MODE, fields.debugMode)
      .putString(APP_VERSION_CODE, fields.appVersionCode)
      .putString(OS_VERSION, fields.osVersion)
      .putString(APP_VERSION, fields.appVersion)
      .putString(BRAND, fields.brand)
      .putString(MODEL, fields.model)
      .apply()
  }

  /// Last saved device fields, or fallback object so receipts are never skipped.
  fun deviceFields(context: Context): PusherDeviceFields {
    val store = prefs(context)
    val appVersionCode = store.getString(APP_VERSION_CODE, null)?.trim()?.takeIf { it.isNotEmpty() } ?: "1"
    val osVersion = store.getString(OS_VERSION, null)?.trim()?.takeIf { it.isNotEmpty() } ?: android.os.Build.VERSION.RELEASE ?: "unknown"
    val appVersion = store.getString(APP_VERSION, null)?.trim()?.takeIf { it.isNotEmpty() } ?: "1.0.0"
    val brand = store.getString(BRAND, null)?.trim()?.takeIf { it.isNotEmpty() } ?: android.os.Build.MANUFACTURER ?: "Android"
    val model = store.getString(MODEL, null)?.trim()?.takeIf { it.isNotEmpty() } ?: android.os.Build.MODEL ?: "Device"

    return PusherDeviceFields(
      isEmulator = store.getBoolean(IS_EMULATOR, false),
      debugMode = store.getBoolean(DEBUG_MODE, false),
      appVersionCode = appVersionCode,
      osVersion = osVersion,
      appVersion = appVersion,
      brand = brand,
      model = model,
    )
  }

  /// Adds [item] to the disk retry queue. Duplicates are replaced, oldest drop at the cap.
  @Synchronized
  fun enqueuePending(context: Context, item: PusherPending) {
    val list = readPending(context).filterNot { it.sameAs(item) }.toMutableList()
    list.add(item)
    while (list.size > MAX_PENDING) list.removeAt(0)
    writePending(context, list)
    PusherLog.d("enqueued pending ${item.kind} total=${list.size}")
  }

  /// Returns and clears the retry queue. Entries older than [PENDING_MAX_AGE_MS] are dropped.
  @Synchronized
  fun drainPending(context: Context): List<PusherPending> {
    val now = System.currentTimeMillis()
    val list = readPending(context).filter { now - it.at < PENDING_MAX_AGE_MS }
    prefs(context).edit().remove(PENDING_QUEUE).apply()
    return list
  }

  private fun readPending(context: Context): List<PusherPending> {
    val raw = prefs(context).getString(PENDING_QUEUE, null) ?: return emptyList()
    return try {
      val array = JSONArray(raw)
      (0 until array.length()).map { PusherPending.fromJson(array.getJSONObject(it)) }
    } catch (_: Exception) {
      emptyList()
    }
  }

  private fun writePending(context: Context, list: List<PusherPending>) {
    val array = JSONArray()
    list.forEach { array.put(it.toJson()) }
    prefs(context).edit().putString(PENDING_QUEUE, array.toString()).apply()
  }

  fun projectId(context: Context): String? {
    return prefs(context).getString(PROJECT_ID, null)?.trim()?.takeIf { it.isNotEmpty() }
  }

  fun statsKey(context: Context): String? {
    return prefs(context).getString(STATS_KEY, null)?.trim()?.takeIf { it.isNotEmpty() }
  }

  /// Fixed API base URL. Not configurable from Flutter.
  fun baseUrl(): String {
    return DEFAULT_BASE_URL
  }

  fun resolveDeviceId(context: Context): String {
    val prefs = prefs(context)
    val existing = prefs.getString(DEVICE_ID, null)?.trim()
    if (!existing.isNullOrEmpty()) {
      val lower = existing.lowercase()
      if (lower != existing) {
        prefs.edit().putString(DEVICE_ID, lower).apply()
      }
      return lower
    }

    val created = UUID.randomUUID().toString().lowercase()
    prefs.edit().putString(DEVICE_ID, created).apply()
    return created
  }

  fun isReady(context: Context): Boolean {
    return projectId(context) != null && statsKey(context) != null
  }
}
