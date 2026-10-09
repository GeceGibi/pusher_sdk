import Foundation

/// Native signed HTTP client for hello and notification receipts.
public enum PusherClient {
  public static let statusDelivered = 1
  public static let statusOpened = 2

  /// Posts device hello. Optional fields come from Flutter device_helpers.
  public static func hello(
    token: String? = nil,
    locale: String? = nil,
    isEmulator: Bool? = nil,
    debugMode: Bool? = nil,
    appVersionCode: String? = nil,
    osVersion: String? = nil,
    appVersion: String? = nil
  ) {
    guard PusherConfig.isReady() else {
      return
    }

    guard
      let appVersionCode = trimmed(appVersionCode),
      let isEmulator,
      let debugMode,
      let projectId = PusherConfig.projectId()
    else {
      return
    }

    var body: [String: Any] = [
      "device_id": PusherConfig.resolveDeviceId(),
      "platform": "ios",
      "locale": trimmed(locale) ?? Locale.current.identifier,
      "is_emulator": isEmulator,
      "debug_mode": debugMode,
      "app_version_code": appVersionCode,
    ]

    if let token = trimmed(token) {
      body["token"] = token
    }

    if let osVersion = trimmed(osVersion) {
      body["os_version"] = osVersion
    }

    if let appVersion = trimmed(appVersion) {
      body["app_version"] = appVersion
    }

    postAsync(path: "/\(projectId)/hi", body: body)
  }

  /// Posts one receipt when [nid] is present. [completion] always fires once.
  public static func receipt(
    nid: String,
    status: Int,
    completion: (() -> Void)? = nil
  ) {
    let trimmedNid = nid.trimmingCharacters(in: .whitespacesAndNewlines)

    guard
      !trimmedNid.isEmpty,
      status == statusDelivered || status == statusOpened,
      PusherConfig.isReady(),
      let projectId = PusherConfig.projectId()
    else {
      completion?()
      return
    }

    let body: [String: Any] = [
      "device_id": PusherConfig.resolveDeviceId(),
      "platform": "ios",
      "status": status,
      "locale": Locale.current.identifier,
    ]

    postAsync(path: "/\(projectId)/n/\(trimmedNid)", body: body, completion: completion)
  }

  /// Delivered / opened from a notification userInfo map when `nid` is set.
  public static func receipt(
    fromUserInfo userInfo: [AnyHashable: Any],
    status: Int,
    completion: (() -> Void)? = nil
  ) {
    receipt(nid: extractNid(from: userInfo) ?? "", status: status, completion: completion)
  }

  private static func extractNid(from userInfo: [AnyHashable: Any]) -> String? {
    if let direct = trimmed(userInfo["nid"] as? String) {
      return direct
    }

    if let data = userInfo["data"] as? [AnyHashable: Any] {
      return trimmed(data["nid"] as? String)
    }

    return nil
  }

  private static func trimmed(_ value: String?) -> String? {
    guard let value else {
      return nil
    }

    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }

  private static func postAsync(
    path: String,
    body: [String: Any],
    completion: (() -> Void)? = nil
  ) {
    DispatchQueue.global(qos: .utility).async {
      defer { completion?() }
      do {
        try post(path: path, body: body)
      } catch {
        // Receipts / hello must not crash the host or NSE.
      }
    }
  }

  private static func post(path: String, body: [String: Any]) throws {
    guard let statsKey = PusherConfig.statsKey() else {
      return
    }

    let rawData = try JSONSerialization.data(withJSONObject: body, options: [])
    guard let raw = String(data: rawData, encoding: .utf8) else {
      return
    }

    let timestamp = Int64(Date().timeIntervalSince1970)
    let signature = PusherHmac.signature(
      method: "POST",
      pathAndQuery: path,
      unixSeconds: timestamp,
      body: raw,
      key: statsKey
    )

    guard let url = URL(string: "\(PusherConfig.baseUrl())/v1\(path)") else {
      return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.timeoutInterval = 15
    request.setValue("application/json", forHTTPHeaderField: "content-type")
    request.setValue("\(timestamp)", forHTTPHeaderField: "x-timestamp")
    request.setValue(signature, forHTTPHeaderField: "x-signature")
    request.httpBody = rawData

    let semaphore = DispatchSemaphore(value: 0)
    var requestError: Error?

    URLSession.shared.dataTask(with: request) { _, _, error in
      requestError = error
      semaphore.signal()
    }.resume()

    _ = semaphore.wait(timeout: .now() + 15)
    if let requestError {
      throw requestError
    }
  }
}
