import Foundation

/// Device fields required on every stats receipt (and hello).
public struct PusherDeviceFields {
  public let isEmulator: Bool
  public let debugMode: Bool
  public let appVersionCode: String
  public let osVersion: String
  public let appVersion: String
  public let brand: String
  public let model: String

  public init(
    isEmulator: Bool,
    debugMode: Bool,
    appVersionCode: String,
    osVersion: String,
    appVersion: String,
    brand: String,
    model: String
  ) {
    self.isEmulator = isEmulator
    self.debugMode = debugMode
    self.appVersionCode = appVersionCode
    self.osVersion = osVersion
    self.appVersion = appVersion
    self.brand = brand
    self.model = model
  }
}

/// Persists project keys and install id. Uses App Group when available (NSE).
public enum PusherConfig {
  public static let projectIdKey = "pusher.project_id"
  public static let statsKeyKey = "pusher.stats_key"
  public static let deviceIdKey = "pusher.device_id"
  public static let isEmulatorKey = "pusher.is_emulator"
  public static let debugModeKey = "pusher.debug_mode"
  public static let appVersionCodeKey = "pusher.app_version_code"
  public static let osVersionKey = "pusher.os_version"
  public static let appVersionKey = "pusher.app_version"
  public static let brandKey = "pusher.brand"
  public static let modelKey = "pusher.model"
  public static let enableLogsKey = "pusher.enable_logs"
  public static let defaultBaseUrl = "https://stats.pusher.tr"

  /// Plugin version; update manually with pubspec.yaml / podspec.
  public static let sdkVersion = "0.0.1"

  /// UserDefaults for the main app or the shared App Group.
  ///
  /// The main app copies an existing install id into the group. The extension
  /// never mints one.
  public static func defaults() -> UserDefaults {
    guard let suiteName = resolveAppGroupId(),
          let suite = UserDefaults(suiteName: suiteName) else {
      return .standard
    }

    if !isExtension {
      copyMissingKeys(from: .standard, to: suite)
    }

    return suite
  }

  /// True inside the Notification Service Extension.
  private static var isExtension: Bool {
    Bundle.main.bundleURL.pathExtension == "appex"
  }

  /// Fills empty App Group keys from the main app's old store.
  private static func copyMissingKeys(from source: UserDefaults, to suite: UserDefaults) {
    let keys = [
      projectIdKey,
      statsKeyKey,
      deviceIdKey,
      isEmulatorKey,
      debugModeKey,
      appVersionCodeKey,
      osVersionKey,
      appVersionKey,
      brandKey,
      modelKey,
      enableLogsKey,
    ]
    var changed = false

    for key in keys {
      if suite.object(forKey: key) != nil {
        continue
      }

      guard let value = source.object(forKey: key) else {
        continue
      }

      suite.set(value, forKey: key)
      changed = true
    }

    if changed {
      suite.synchronize()
    }
  }

  /// App Group id is always `group.<mainBundleId>`.
  ///
  /// Host must enable that exact group on Runner + Notification Service
  /// Extension entitlements. There is no runtime override.
  public static func resolveAppGroupId() -> String? {
    guard let mainBundleId = mainAppBundleIdentifier() else {
      return nil
    }

    return "group.\(mainBundleId)"
  }

  /// Main app bundle id. Inside an appex, drops the last bundle component.
  public static func mainAppBundleIdentifier() -> String? {
    guard let bundleId = Bundle.main.bundleIdentifier else {
      return nil
    }

    if Bundle.main.bundleURL.pathExtension == "appex" {
      let parts = bundleId.split(separator: ".")
      if parts.count > 1 {
        return parts.dropLast().joined(separator: ".")
      }
    }

    return bundleId
  }

  /// Stores [projectId] and [statsKey] only.
  public static func save(
    projectId: String,
    statsKey: String
  ) {
    let store = defaults()
    store.set(projectId, forKey: projectIdKey)
    store.set(statsKey, forKey: statsKeyKey)
    store.synchronize()
  }

  /// Persists and applies non-error logging for native + NSE.
  public static func setEnableLogs(_ enabled: Bool) {
    let store = defaults()
    store.set(enabled, forKey: enableLogsKey)
    store.synchronize()
    PusherLog.enabled = enabled
  }

  /// Restores `PusherLog.enabled` from defaults (NSE / cold start).
  public static func syncLogging() {
    PusherLog.enabled = defaults().bool(forKey: enableLogsKey)
  }

  public static let pendingReceiptsKey = "pusher.pending_receipts"

  /// Persists device fields from hello so NSE receipts can reuse them.
  public static func saveDeviceFields(_ fields: PusherDeviceFields) {
    let store = defaults()
    store.set(fields.isEmulator, forKey: isEmulatorKey)
    store.set(fields.debugMode, forKey: debugModeKey)
    store.set(fields.appVersionCode, forKey: appVersionCodeKey)
    store.set(fields.osVersion, forKey: osVersionKey)
    store.set(fields.appVersion, forKey: appVersionKey)
    store.set(fields.brand, forKey: brandKey)
    store.set(fields.model, forKey: modelKey)
    store.synchronize()
  }

  /// Last saved device fields, or fallback object so receipts are never skipped.
  public static func deviceFields() -> PusherDeviceFields {
    let store = defaults()
    let appVersionCode = trimmed(store.string(forKey: appVersionCodeKey)) ?? "1"
    let osVersion = trimmed(store.string(forKey: osVersionKey)) ?? ProcessInfo.processInfo.operatingSystemVersionString
    let appVersion = trimmed(store.string(forKey: appVersionKey)) ?? "1.0.0"
    let brand = trimmed(store.string(forKey: brandKey)) ?? "Apple"
    let model = trimmed(store.string(forKey: modelKey)) ?? "iPhone"

    return PusherDeviceFields(
      isEmulator: store.bool(forKey: isEmulatorKey),
      debugMode: store.bool(forKey: debugModeKey),
      appVersionCode: appVersionCode,
      osVersion: osVersion,
      appVersion: appVersion,
      brand: brand,
      model: model
    )
  }

  /// Saves an unposted receipt into local disk queue to retry later.
  public static func enqueuePendingReceipt(nid: String, status: Int) {
    let trimmedNid = nid.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedNid.isEmpty else { return }
    let store = defaults()
    var current = store.stringArray(forKey: pendingReceiptsKey) ?? []
    let entry = "\(trimmedNid):\(status)"
    if !current.contains(entry) {
      current.append(entry)
      store.set(current, forKey: pendingReceiptsKey)
      store.synchronize()
      PusherLog.d("enqueued pending receipt: \(trimmedNid) status=\(status) total=\(current.count)")
    }
  }

  /// Returns and clears all pending receipts from disk queue.
  public static func drainPendingReceipts() -> [(nid: String, status: Int)] {
    let store = defaults()
    guard let list = store.stringArray(forKey: pendingReceiptsKey), !list.isEmpty else {
      return []
    }
    store.removeObject(forKey: pendingReceiptsKey)
    store.synchronize()
    return list.compactMap { item in
      let parts = item.split(separator: ":")
      guard parts.count == 2, let status = Int(parts[1]) else { return nil }
      return (nid: String(parts[0]), status: status)
    }
  }

  public static func projectId() -> String? {
    trimmed(defaults().string(forKey: projectIdKey))
  }

  public static func statsKey() -> String? {
    trimmed(defaults().string(forKey: statsKeyKey))
  }

  /// Fixed API base URL. Not configurable from Flutter.
  public static func baseUrl() -> String {
    return defaultBaseUrl
  }

  public static func resolveDeviceId() -> String {
    let store = defaults()
    if let existing = trimmed(store.string(forKey: deviceIdKey)) {
      let lower = existing.lowercased()
      if lower != existing {
        store.set(lower, forKey: deviceIdKey)
        store.synchronize()
      }
      return lower
    }

    if isExtension {
      return ""
    }

    if store !== UserDefaults.standard,
       let legacy = trimmed(UserDefaults.standard.string(forKey: deviceIdKey)) {
      let lower = legacy.lowercased()
      store.set(lower, forKey: deviceIdKey)
      store.synchronize()
      return lower
    }

    let created = UUID().uuidString.lowercased()
    store.set(created, forKey: deviceIdKey)
    store.synchronize()
    return created
  }

  public static func isReady() -> Bool {
    projectId() != nil && statsKey() != nil
  }

  private static func trimmed(_ value: String?) -> String? {
    guard let value else {
      return nil
    }

    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }
}
