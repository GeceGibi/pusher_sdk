package com.pusher.sdk

import android.util.Base64
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

/// HMAC-SHA256 signing for the stats API.
internal object PusherHmac {
  fun signature(
    method: String,
    pathAndQuery: String,
    unixSeconds: Long,
    body: String,
    key: String,
  ): String {
    val canonical = listOf(
      method.uppercase(),
      pathAndQuery,
      unixSeconds.toString(),
      body,
    ).joinToString("\n")

    val mac = Mac.getInstance("HmacSHA256")
    mac.init(SecretKeySpec(key.toByteArray(Charsets.UTF_8), "HmacSHA256"))
    val digest = mac.doFinal(canonical.toByteArray(Charsets.UTF_8))
    return Base64.encodeToString(digest, Base64.NO_WRAP)
  }
}
