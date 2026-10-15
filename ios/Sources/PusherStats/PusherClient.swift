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
    appVersion: String? = nil,
    brand: String? = nil,
    model: String? = nil
  ) {
    guard PusherConfig.isReady() else {
      PusherLog.w("hello skip: config not ready")
      return
    }

    guard
      let appVersionCode = trimmed(appVersionCode),
      let isEmulator,
      let debugMode,
      let osVersion = trimmed(osVersion),
      let appVersion = trimmed(appVersion),
      let brand = trimmed(brand),
      let model = trimmed(model),
      let projectId = PusherConfig.projectId()
    else {
      PusherLog.w("hello skip: missing required device fields")
      return
    }

    let fields = PusherDeviceFields(
      isEmulator: isEmulator,
      debugMode: debugMode,
      appVersionCode: appVersionCode,
      osVersion: osVersion,
      appVersion: appVersion,
      brand: brand,
      model: model
    )
    PusherConfig.saveDeviceFields(fields)

    var body: [String: Any] = [
      "clientId": PusherConfig.resolveDeviceId(),
      "platform": "ios",
      "locale": trimmed(locale) ?? Locale.current.identifier,
      "isEmulator": fields.isEmulator,
      "debugMode": fields.debugMode,
      "appVersionCode": fields.appVersionCode,
      "sdkVersion": PusherConfig.sdkVersion,
      "osVersion": fields.osVersion,
      "appVersion": fields.appVersion,
      "brand": fields.brand,
      "model": fields.model,
    ]

    if let token = trimmed(token) {
      body["token"] = token
    }

    PusherLog.d("hello enqueue projectId=\(projectId)")
    postAsync(path: "/\(projectId)/hi", body: body, completion: {
      flushPendingReceipts()
    })
  }

  /// Flushes any pending receipts queued from offline or failed previous attempts.
  public static func flushPendingReceipts() {
    let pending = PusherConfig.drainPendingReceipts()
    guard !pending.isEmpty else { return }
    PusherLog.d("flushing \(pending.count) pending receipts")
    for item in pending {
      receipt(nid: item.nid, status: item.status)
    }
  }

  /// Posts one receipt when [nid] is present. [completion] always fires once.
  public static func receipt(
    nid: String,
    status: Int,
    completion: (() -> Void)? = nil
  ) {
    let trimmedNid = nid.trimmingCharacters(in: .whitespacesAndNewlines)
    let ready = PusherConfig.isReady()
    let projectId = PusherConfig.projectId()

    guard
      !trimmedNid.isEmpty,
      status == statusDelivered || status == statusOpened,
      ready,
      let projectId
    else {
      PusherLog.w(
        "receipt skip: nid='\(trimmedNid)' status=\(status) ready=\(ready) " +
          "projectId=\(projectId ?? "nil")"
      )
      if !trimmedNid.isEmpty && (status == statusDelivered || status == statusOpened) {
        PusherConfig.enqueuePendingReceipt(nid: trimmedNid, status: status)
      }
      completion?()
      return
    }

    var deviceId = PusherConfig.resolveDeviceId()
    if deviceId.isEmpty {
      deviceId = UUID().uuidString.lowercased()
    }

    let fields = PusherConfig.deviceFields()

    let body: [String: Any] = [
      "clientId": deviceId,
      "platform": "ios",
      "status": status,
      "locale": Locale.current.identifier,
      "isEmulator": fields.isEmulator,
      "debugMode": fields.debugMode,
      "appVersionCode": fields.appVersionCode,
      "sdkVersion": PusherConfig.sdkVersion,
      "osVersion": fields.osVersion,
      "appVersion": fields.appVersion,
      "brand": fields.brand,
      "model": fields.model,
    ]

    PusherLog.d("receipt enqueue nid=\(trimmedNid) status=\(status)")
    postAsync(path: "/\(projectId)/n/\(trimmedNid)", body: body, completion: completion, onError: {
      PusherConfig.enqueuePendingReceipt(nid: trimmedNid, status: status)
    })
  }

  /// Delivered / opened from a notification userInfo map when `nid` is set.
  public static func receipt(
    fromUserInfo userInfo: [AnyHashable: Any],
    status: Int,
    completion: (() -> Void)? = nil
  ) {
    let nid = extractNid(from: userInfo) ?? ""
    PusherLog.d("receipt fromUserInfo nid=\(nid) status=\(status)")
    receipt(nid: nid, status: status, completion: completion)
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
    completion: (() -> Void)? = nil,
    onError: (() -> Void)? = nil
  ) {
    DispatchQueue.global(qos: .utility).async {
      defer { completion?() }
      do {
        try post(path: path, body: body)
      } catch {
        PusherLog.e("POST \(path) failed: \(error)")
        onError?()
      }
    }
  }

  private static func post(path: String, body: [String: Any]) throws {
    guard let statsKey = PusherConfig.statsKey() else {
      PusherLog.w("POST \(path) skip: statsKey null")
      throw NSError(domain: "Pusher", code: -1, userInfo: [NSLocalizedDescriptionKey: "statsKey null"])
    }

    let rawData = try JSONSerialization.data(withJSONObject: body, options: [])
    guard let raw = String(data: rawData, encoding: .utf8) else {
      PusherLog.w("POST \(path) skip: body encode failed")
      throw NSError(domain: "Pusher", code: -2, userInfo: [NSLocalizedDescriptionKey: "body encode failed"])
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
      PusherLog.w("POST \(path) skip: bad url")
      throw NSError(domain: "Pusher", code: -3, userInfo: [NSLocalizedDescriptionKey: "bad url"])
    }

    PusherLog.d("POST start \(url) body=\(raw)")

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.timeoutInterval = 15
    request.setValue("application/json", forHTTPHeaderField: "content-type")
    request.setValue("\(timestamp)", forHTTPHeaderField: "x-timestamp")
    request.setValue(signature, forHTTPHeaderField: "x-signature")
    request.httpBody = rawData

    let semaphore = DispatchSemaphore(value: 0)
    var requestError: Error?
    var statusCode = -1
    var responseBody = ""

    URLSession.shared.dataTask(with: request) { data, response, error in
      requestError = error
      statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
      if let data, let text = String(data: data, encoding: .utf8) {
        responseBody = text
      }
      semaphore.signal()
    }.resume()

    _ = semaphore.wait(timeout: .now() + 15)
    if let requestError {
      throw requestError
    }

    PusherLog.d("POST response path=\(path) http=\(statusCode) body=\(responseBody)")
    if statusCode < 200 || statusCode > 299 {
      throw NSError(domain: "Pusher", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(statusCode): \(responseBody)"])
    }
  }
}
