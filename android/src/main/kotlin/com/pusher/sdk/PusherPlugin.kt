package com.pusher.sdk

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/// Flutter MethodChannel bridge into native config + HTTP.
class PusherPlugin : FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private var context: Context? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    context = binding.applicationContext
    channel = MethodChannel(binding.binaryMessenger, "pusher")
    channel.setMethodCallHandler(this)
    PusherConfig.syncLogging(binding.applicationContext)
    PusherLog.d("plugin attached")
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    context = null
    PusherLog.d("plugin detached")
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    val ctx = context
    if (ctx == null) {
      PusherLog.w("method ${call.method} skip: no context")
      result.error("no_context", "Plugin not attached", null)
      return
    }

    PusherLog.d("method ${call.method}")

    when (call.method) {
      "init" -> {
        val projectId = call.argument<String>("projectId")?.trim().orEmpty()
        val statsKey = call.argument<String>("statsKey")?.trim().orEmpty()

        if (projectId.isEmpty() || statsKey.isEmpty()) {
          PusherLog.w("init invalid_args")
          result.error("invalid_args", "projectId and statsKey required", null)
          return
        }

        PusherConfig.save(ctx, projectId, statsKey)
        val enableLogs = call.argument<Boolean>("enableLogs") ?: false
        PusherConfig.setEnableLogs(ctx, enableLogs)
        val deviceId = PusherConfig.resolveDeviceId(ctx)
        PusherLog.d("init saved projectId=$projectId deviceId=$deviceId")
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
        PusherLog.d("channel receipt nid=$nid status=$status")
        PusherClient.receipt(ctx, nid, status)
        result.success(null)
      }

      "deviceId" -> {
        if (!PusherConfig.isReady(ctx)) {
          PusherLog.w("deviceId skip: not ready")
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
      brand = call.argument("brand"),
      model = call.argument("model"),
    )
  }
}
