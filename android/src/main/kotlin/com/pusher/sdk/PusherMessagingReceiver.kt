package com.pusher.sdk

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.google.firebase.messaging.RemoteMessage

/// Native FCM receive hook. Posts delivered when `data.nid` is set.
class PusherMessagingReceiver : BroadcastReceiver() {
  override fun onReceive(context: Context, intent: Intent) {
    PusherLog.d("receiver.onReceive action=${intent.action}")

    val extras = intent.extras
    if (extras == null) {
      PusherLog.w("receiver skip: extras=null")
      return
    }

    val data = RemoteMessage(extras).data
    PusherLog.d("receiver dataKeys=${data.keys} nid=${data["nid"]} ready=${PusherConfig.isReady(context)}")

    if (data.isEmpty()) {
      PusherLog.w("receiver skip: data empty")
      return
    }

    // Keep the process alive until the POST completes.
    val pending = goAsync()
    PusherClient.receiptFromData(context, data, PusherClient.STATUS_DELIVERED) {
      PusherLog.d("receiver goAsync finished")
      pending.finish()
    }
  }
}
