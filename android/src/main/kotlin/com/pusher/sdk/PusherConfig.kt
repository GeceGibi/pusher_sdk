package com.pusher.sdk

import android.content.Context
import android.content.SharedPreferences
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
  const val PENDING_RECEIPTS = "pusher.pending_receipts"
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

  /// Saves an unposted receipt into local disk queue to retry later.
  @Synchronized
  fun enqueuePendingReceipt(context: Context, nid: String, status: Int) {
    val trimmed = nid.trim()
    if (trimmed.isEmpty()) return
    val prefs = prefs(context)
    val set = prefs.getStringSet(PENDING_RECEIPTS, emptySet())?.toMutableSet() ?: mutableSetOf()
    set.add("$trimmed:$status")
    prefs.edit().putStringSet(PENDING_RECEIPTS, set).apply()
    PusherLog.d("enqueued pending receipt: $trimmed status=$status total=${set.size}")
  }

  /// Returns and clears all pending receipts from disk queue.
  @Synchronized
  fun drainPendingReceipts(context: Context): List<Pair<String, Int>> {
    val prefs = prefs(context)
    val set = prefs.getStringSet(PENDING_RECEIPTS, null)
    if (set.isNullOrEmpty()) return emptyList()
    prefs.edit().remove(PENDING_RECEIPTS).apply()
    return set.mapNotNull { item ->
      val parts = item.split(":")
      if (parts.size == 2) {
        val nid = parts[0]
        val status = parts[1].toIntOrNull()
        if (status != null) Pair(nid, status) else null
      } else null
    }
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
