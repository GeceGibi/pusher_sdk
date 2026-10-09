package com.pusher.sdk

import android.util.Log

/// Shared logcat tag for all native Pusher diagnostics.
///
/// Filter: `adb logcat -s Pusher`
///
/// [d] / [w] respect [enabled] (from Flutter [enableLogs]). [e] always logs.
internal object PusherLog {
  const val TAG = "Pusher"

  /// Non-error diagnostics. Synced from prefs on init / receiver.
  @Volatile
  var enabled: Boolean = false

  fun d(message: String) {
    if (!enabled) {
      return
    }

    Log.d(TAG, message)
  }

  fun w(message: String) {
    if (!enabled) {
      return
    }

    Log.w(TAG, message)
  }

  fun e(message: String, error: Throwable? = null) {
    if (error == null) {
      Log.e(TAG, message)
    } else {
      Log.e(TAG, message, error)
    }
  }
}
