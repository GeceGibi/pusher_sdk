import Foundation

/// Device fields required on every stats receipt (and hello).
public struct PusherDeviceFields {
  public let isEmulator: Bool
  public let debugMode: Bool
  public let appVersionCode: String
  public let osVersion: String?
  public let appVersion: String?
  public let brand: String?
  public let model: String?

  public init(
    isEmulator: Bool,
    debugMode: Bool,
    appVersionCode: String,
    osVersion: String? = nil,
    appVersion: String? = nil,
    brand: String? = nil,
    model: String? = nil
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
  public static let sdkVersion = "0.10.0"

  /// UserDefaults for the main app or the shared App Group.
  public static func defaults() -> UserDefaults {
    if let suiteName = resolveAppGroupId(),
       let suite = UserDefaults(suiteName: suiteName) {
      return suite
    }

    return .standard
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

  /// Persists device fields from hello so NSE receipts can reuse them.
  public static func saveDeviceFields(_ fields: PusherDeviceFields) {
    let store = defaults()
    store.set(fields.isEmulator, forKey: isEmulatorKey)
    store.set(fields.debugMode, forKey: debugModeKey)
    store.set(fields.appVersionCode, forKey: appVersionCodeKey)

    if let osVersion = trimmed(fields.osVersion) {
      store.set(osVersion, forKey: osVersionKey)
    } else {
      store.removeObject(forKey: osVersionKey)
    }

    if let appVersion = trimmed(fields.appVersion) {
      store.set(appVersion, forKey: appVersionKey)
    } else {
      store.removeObject(forKey: appVersionKey)
    }

    if let brand = trimmed(fields.brand) {
      store.set(brand, forKey: brandKey)
    } else {
      store.removeObject(forKey: brandKey)
    }

    if let model = trimmed(fields.model) {
      store.set(model, forKey: modelKey)
    } else {
      store.removeObject(forKey: modelKey)
    }

    store.synchronize()
  }

  /// Last saved device fields, or nil when hello has not stored them yet.
  public static func deviceFields() -> PusherDeviceFields? {
    let store = defaults()
    guard store.object(forKey: isEmulatorKey) != nil,
          store.object(forKey: debugModeKey) != nil,
          let appVersionCode = trimmed(store.string(forKey: appVersionCodeKey))
    else {
      return nil
    }

    return PusherDeviceFields(
      isEmulator: store.bool(forKey: isEmulatorKey),
      debugMode: store.bool(forKey: debugModeKey),
      appVersionCode: appVersionCode,
      osVersion: trimmed(store.string(forKey: osVersionKey)),
      appVersion: trimmed(store.string(forKey: appVersionKey)),
      brand: trimmed(store.string(forKey: brandKey)),
      model: trimmed(store.string(forKey: modelKey))
    )
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
      return existing
    }

    let created = UUID().uuidString
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
