package com.pusher.pusher_sdk

import android.content.Context
import android.content.SharedPreferences
import java.util.UUID

/// Persists project keys and stable install id for native hello / receipts.
internal object PusherConfig {
  private const val PREFS = "pusher_sdk"
  const val PROJECT_ID = "pusher_sdk.project_id"
  const val STATS_KEY = "pusher_sdk.stats_key"
  const val DEVICE_ID = "pusher_sdk.device_id"
  const val DEFAULT_BASE_URL = "https://stats.pusher.tr"

  fun prefs(context: Context): SharedPreferences {
    return context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
  }

  /// Stores [projectId] and [statsKey] only. Stats host is fixed.
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

  fun projectId(context: Context): String? {
    return prefs(context).getString(PROJECT_ID, null)?.trim()?.takeIf { it.isNotEmpty() }
  }

  fun statsKey(context: Context): String? {
    return prefs(context).getString(STATS_KEY, null)?.trim()?.takeIf { it.isNotEmpty() }
  }

  /// Fixed stats host. Not configurable from Flutter.
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
