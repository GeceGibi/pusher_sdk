import Flutter
import UIKit

/// Flutter MethodChannel bridge into native config + HTTP.
public class PusherSdkPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "pusher",
      binaryMessenger: registrar.messenger()
    )
    let instance = PusherSdkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]

    switch call.method {
    case "init":
      guard
        let projectId = stringArg(args, "projectId"),
        let statsKey = stringArg(args, "statsKey")
      else {
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
      helloFromArgs(args)
      result(PusherConfig.resolveDeviceId())

    case "hello":
      helloFromArgs(args)
      result(nil)

    case "receipt":
      let nid = stringArg(args, "nid") ?? ""
      let status = args["status"] as? Int ?? -1
      PusherClient.receipt(nid: nid, status: status)
      result(nil)

    case "deviceId":
      guard PusherConfig.isReady() else {
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
