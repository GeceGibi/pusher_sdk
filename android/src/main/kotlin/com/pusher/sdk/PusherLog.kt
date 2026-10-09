package com.pusher.sdk

import android.util.Log

/// Shared logcat tag for all native Pusher diagnostics.
///
/// Filter: `adb logcat -s Pusher`
internal object PusherLog {
  const val TAG = "Pusher"

  fun d(message: String) {
    Log.d(TAG, message)
  }

  fun w(message: String) {
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
