import Flutter
import UIKit

/// Flutter MethodChannel bridge into native config + HTTP.
public class PusherPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "pusher",
      binaryMessenger: registrar.messenger()
    )
    let instance = PusherPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    PusherConfig.syncLogging()
    PusherLog.d("plugin registered")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    PusherLog.d("method \(call.method)")

    switch call.method {
    case "init":
      guard
        let projectId = stringArg(args, "projectId"),
        let statsKey = stringArg(args, "statsKey")
      else {
        PusherLog.w("init invalid_args")
        result(
          FlutterError(
            code: "invalid_args",
            message: "projectId and statsKey required",
            details: nil
          )
        )
        return
      }

      PusherConfig.save(
        projectId: projectId,
        statsKey: statsKey
      )
      let enableLogs = args["enableLogs"] as? Bool ?? false
      PusherConfig.setEnableLogs(enableLogs)
      let deviceId = PusherConfig.resolveDeviceId()
      PusherLog.d("init saved projectId=\(projectId) deviceId=\(deviceId)")
      helloFromArgs(args)
      result(deviceId)

    case "hello":
      helloFromArgs(args)
      result(nil)

    case "receipt":
      let nid = stringArg(args, "nid") ?? ""
      let status = args["status"] as? Int ?? -1
      PusherLog.d("channel receipt nid=\(nid) status=\(status)")
      PusherClient.receipt(nid: nid, status: status)
      result(nil)

    case "deviceId":
      guard PusherConfig.isReady() else {
        PusherLog.w("deviceId skip: not ready")
        result(nil)
        return
      }

      result(PusherConfig.resolveDeviceId())

    case "isInitialized":
      result(PusherConfig.isReady())

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func helloFromArgs(_ args: [String: Any]) {
    PusherClient.hello(
      token: stringArg(args, "token"),
      locale: stringArg(args, "locale"),
      isEmulator: args["isEmulator"] as? Bool,
      debugMode: args["debugMode"] as? Bool,
      appVersionCode: stringArg(args, "appVersionCode"),
      osVersion: stringArg(args, "osVersion"),
      appVersion: stringArg(args, "appVersion")
    )
  }

  private func stringArg(_ args: [String: Any], _ key: String) -> String? {
    guard let value = args[key] as? String else {
      return nil
    }

    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }
}
