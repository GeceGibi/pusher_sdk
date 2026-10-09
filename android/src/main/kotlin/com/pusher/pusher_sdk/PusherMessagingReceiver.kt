package com.pusher.pusher_sdk

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.google.firebase.messaging.RemoteMessage

/// Native FCM receive hook. Posts delivered when `data.nid` is set.
class PusherMessagingReceiver : BroadcastReceiver() {
  override fun onReceive(context: Context, intent: Intent) {
    val extras = intent.extras ?: return
    val data = RemoteMessage(extras).data
    if (data.isEmpty()) {
      return
    }

    // Keep the process alive until the POST completes.
    val pending = goAsync()
    PusherClient.receiptFromData(context, data, PusherClient.STATUS_DELIVERED) {
      pending.finish()
    }
  }
}
