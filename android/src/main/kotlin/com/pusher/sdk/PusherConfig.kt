package com.pusher.sdk

import android.content.Context
import android.content.SharedPreferences
import java.util.UUID

/// Device fields required on every stats receipt (and hello).
internal data class PusherDeviceFields(
  val isEmulator: Boolean,
  val debugMode: Boolean,
  val appVersionCode: String,
  val osVersion: String? = null,
  val appVersion: String? = null,
  val brand: String? = null,
  val model: String? = null,
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
  const val DEFAULT_BASE_URL = "https://stats.pusher.tr"

  /// Plugin version; update manually with pubspec.yaml / podspec.
  const val SDK_VERSION = "0.10.0"

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
    val editor = prefs(context)
      .edit()
      .putBoolean(IS_EMULATOR, fields.isEmulator)
      .putBoolean(DEBUG_MODE, fields.debugMode)
      .putString(APP_VERSION_CODE, fields.appVersionCode)

    val osVersion = fields.osVersion?.trim()
    if (osVersion.isNullOrEmpty()) {
      editor.remove(OS_VERSION)
    } else {
      editor.putString(OS_VERSION, osVersion)
    }

    val appVersion = fields.appVersion?.trim()
    if (appVersion.isNullOrEmpty()) {
      editor.remove(APP_VERSION)
    } else {
      editor.putString(APP_VERSION, appVersion)
    }

    val brand = fields.brand?.trim()
    if (brand.isNullOrEmpty()) {
      editor.remove(BRAND)
    } else {
      editor.putString(BRAND, brand)
    }

    val model = fields.model?.trim()
    if (model.isNullOrEmpty()) {
      editor.remove(MODEL)
    } else {
      editor.putString(MODEL, model)
    }

    editor.apply()
  }

  /// Last saved device fields, or null when hello has not stored them yet.
  fun deviceFields(context: Context): PusherDeviceFields? {
    val store = prefs(context)
    if (!store.contains(IS_EMULATOR) ||
      !store.contains(DEBUG_MODE) ||
      !store.contains(APP_VERSION_CODE)
    ) {
      return null
    }

    val appVersionCode = store.getString(APP_VERSION_CODE, null)?.trim()
    if (appVersionCode.isNullOrEmpty()) {
      return null
    }

    return PusherDeviceFields(
      isEmulator = store.getBoolean(IS_EMULATOR, false),
      debugMode = store.getBoolean(DEBUG_MODE, false),
      appVersionCode = appVersionCode,
      osVersion = store.getString(OS_VERSION, null)?.trim()?.takeIf { it.isNotEmpty() },
      appVersion = store.getString(APP_VERSION, null)?.trim()?.takeIf { it.isNotEmpty() },
      brand = store.getString(BRAND, null)?.trim()?.takeIf { it.isNotEmpty() },
      model = store.getString(MODEL, null)?.trim()?.takeIf { it.isNotEmpty() },
    )
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
    val existing = prefs(context).getString(DEVICE_ID, null)?.trim()
    if (!existing.isNullOrEmpty()) {
      return existing
    }

    val created = UUID.randomUUID().toString()
    prefs(context).edit().putString(DEVICE_ID, created).apply()
    return created
  }

  fun isReady(context: Context): Boolean {
    return projectId(context) != null && statsKey(context) != null
  }
}
