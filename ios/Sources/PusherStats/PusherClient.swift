import Foundation

/// Native signed HTTP client for hello and notification receipts.
///
/// A request that fails on the network, with 408, 429 or 5xx, is saved to a disk
/// queue and retried with backoff for up to 48 hours. Other 4xx answers are final.
public enum PusherClient {
  public static let statusDelivered = 1
  public static let statusOpened = 2

  private static let retryDelays: [TimeInterval] = [30, 120, 600, 1800, 3600]
  private static let queue = DispatchQueue(label: "tr.pusher.sdk.client", qos: .utility)

  /// Touched only on [queue].
  private static var attempt = 0
  private static var retryScheduled = false

  private struct HttpFailure: Error {
    let code: Int
    let body: String
  }

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

    if let appVersionCode = trimmed(appVersionCode),
       let isEmulator,
       let debugMode,
       let osVersion = trimmed(osVersion),
       let appVersion = trimmed(appVersion),
       let brand = trimmed(brand),
       let model = trimmed(model) {
      PusherConfig.saveDeviceFields(PusherDeviceFields(
        isEmulator: isEmulator,
        debugMode: debugMode,
        appVersionCode: appVersionCode,
        osVersion: osVersion,
        appVersion: appVersion,
        brand: brand,
        model: model
      ))
    }

    submit(PusherPending(kind: .hello, token: trimmed(token), locale: trimmed(locale)))
  }

  /// Sends everything waiting in the retry queue.
  public static func flushPending() {
    queue.async { flush() }
  }

  /// Posts one receipt when [nid] is present. [completion] always fires once.
  public static func receipt(
    nid: String,
    status: Int,
    completion: (() -> Void)? = nil
  ) {
    let trimmedNid = nid.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmedNid.isEmpty, status == statusDelivered || status == statusOpened else {
      PusherLog.w("receipt skip: nid='\(trimmedNid)' status=\(status)")
      completion?()
      return
    }

    let item = PusherPending(kind: .receipt, nid: trimmedNid, status: status)

    guard PusherConfig.isReady() else {
      PusherLog.w("receipt queued: config not ready nid=\(trimmedNid)")
      PusherConfig.enqueuePending(item)
      completion?()
      return
    }

    submit(item, completion: completion)
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

  private static func submit(_ item: PusherPending, completion: (() -> Void)? = nil) {
    queue.async {
      defer { completion?() }
      if send(item) {
        flush()
      }
    }
  }

  /// Sends the queue in order. Stops at the first retryable failure.
  private static func flush() {
    let items = PusherConfig.drainPending()
    guard !items.isEmpty else { return }
    PusherLog.d("flushing \(items.count) pending")

    for (index, item) in items.enumerated() {
      if !send(item) {
        items.dropFirst(index + 1).forEach { PusherConfig.enqueuePending($0) }
        return
      }
    }
  }

  /// True when the item is done (sent or rejected for good). False when queued for retry.
  private static func send(_ item: PusherPending) -> Bool {
    do {
      try post(item)
      attempt = 0
      return true
    } catch let error as HttpFailure {
      PusherLog.e("\(item.kind.rawValue) failed: HTTP \(error.code) \(error.body)")
      let retryable = error.code == 408 || error.code == 429 || error.code >= 500
      if !retryable {
        return true
      }
    } catch {
      PusherLog.e("\(item.kind.rawValue) failed: \(error)")
    }

    PusherConfig.enqueuePending(item)
    scheduleRetry()
    return false
  }

  private static func scheduleRetry() {
    guard !retryScheduled else { return }
    retryScheduled = true
    let delay = retryDelays[min(attempt, retryDelays.count - 1)]
    attempt += 1
    PusherLog.d("retry in \(Int(delay))s")
    queue.asyncAfter(deadline: .now() + delay) {
      retryScheduled = false
      flush()
    }
  }

  private static func post(_ item: PusherPending) throws {
    guard let projectId = PusherConfig.projectId(), let statsKey = PusherConfig.statsKey() else {
      throw NSError(domain: "Pusher", code: -1, userInfo: [NSLocalizedDescriptionKey: "config missing"])
    }

    var deviceId = PusherConfig.resolveDeviceId()
    if deviceId.isEmpty {
      deviceId = UUID().uuidString.lowercased()
    }

    let fields = PusherConfig.deviceFields()
    var body: [String: Any] = [
      "clientId": deviceId,
      "platform": "ios",
      "locale": item.locale ?? Locale.current.identifier,
      "isEmulator": fields.isEmulator,
      "debugMode": fields.debugMode,
      "appVersionCode": fields.appVersionCode,
      "sdkVersion": PusherConfig.sdkVersion,
      "osVersion": fields.osVersion,
      "appVersion": fields.appVersion,
      "brand": fields.brand,
      "model": fields.model,
    ]

    let path: String
    if item.kind == .hello {
      if let token = item.token { body["token"] = token }
      path = "/\(projectId)/hi"
    } else {
      body["status"] = item.status
      path = "/\(projectId)/n/\(item.nid ?? "")"
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
      throw HttpFailure(code: statusCode, body: responseBody)
    }
  }
}
