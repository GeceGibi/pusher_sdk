import Foundation

/// Persists project keys and install id. Uses App Group when available (NSE).
public enum PusherConfig {
  public static let projectIdKey = "pusher_sdk.project_id"
  public static let statsKeyKey = "pusher_sdk.stats_key"
  public static let deviceIdKey = "pusher_sdk.device_id"
  public static let defaultBaseUrl = "https://stats.pusher.tr"

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

  /// Stores [projectId] and [statsKey] only. Stats host is fixed.
  public static func save(
    projectId: String,
    statsKey: String
  ) {
    let store = defaults()
    store.set(projectId, forKey: projectIdKey)
    store.set(statsKey, forKey: statsKeyKey)
    store.synchronize()
  }

  public static func projectId() -> String? {
    trimmed(defaults().string(forKey: projectIdKey))
  }

  public static func statsKey() -> String? {
    trimmed(defaults().string(forKey: statsKeyKey))
  }

  /// Fixed stats host. Not configurable from Flutter.
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
