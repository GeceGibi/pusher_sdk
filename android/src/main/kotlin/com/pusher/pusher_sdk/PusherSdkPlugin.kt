package com.pusher.pusher_sdk

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/// Flutter MethodChannel bridge into native config + HTTP.
class PusherSdkPlugin : FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private var context: Context? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    context = binding.applicationContext
    channel = MethodChannel(binding.binaryMessenger, "pusher_sdk")
    channel.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    context = null
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    val ctx = context
    if (ctx == null) {
      result.error("no_context", "Plugin not attached", null)
      return
    }

    when (call.method) {
      "init" -> {
        val projectId = call.argument<String>("projectId")?.trim().orEmpty()
        val statsKey = call.argument<String>("statsKey")?.trim().orEmpty()

        if (projectId.isEmpty() || statsKey.isEmpty()) {
          result.error("invalid_args", "projectId and statsKey required", null)
          return
        }

        PusherConfig.save(ctx, projectId, statsKey)
        val deviceId = PusherConfig.resolveDeviceId(ctx)
        helloFromCall(ctx, call)
        result.success(deviceId)
      }

      "hello" -> {
        helloFromCall(ctx, call)
        result.success(null)
      }

      "receipt" -> {
        val nid = call.argument<String>("nid")?.trim().orEmpty()
        val status = call.argument<Int>("status") ?: -1
        PusherClient.receipt(ctx, nid, status)
        result.success(null)
      }

      "deviceId" -> {
        if (!PusherConfig.isReady(ctx)) {
          result.success(null)
          return
        }

        result.success(PusherConfig.resolveDeviceId(ctx))
      }

      "isInitialized" -> {
        result.success(PusherConfig.isReady(ctx))
      }

      else -> result.notImplemented()
    }
  }

  private fun helloFromCall(context: Context, call: MethodCall) {
    PusherClient.hello(
      context = context,
      token = call.argument("token"),
      locale = call.argument("locale"),
      isEmulator = call.argument("isEmulator"),
      debugMode = call.argument("debugMode"),
      appVersionCode = call.argument("appVersionCode"),
      osVersion = call.argument("osVersion"),
      appVersion = call.argument("appVersion"),
    )
  }
}
