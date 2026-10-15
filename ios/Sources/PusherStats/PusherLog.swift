import Foundation
import os

/// Shared logger for native Pusher diagnostics.
///
/// Filter Console / device logs for subsystem `tr.pusher.sdk` or message prefix `Pusher`.
///
/// `d` / `w` respect `enabled` (from Flutter `enableLogs`). `e` always logs.
public enum PusherLog {
  private static let logger = Logger(subsystem: "tr.pusher.sdk", category: "Pusher")

  /// Non-error diagnostics. Synced from defaults on init / NSE.
  public static var enabled: Bool = false

  public static func d(_ message: String) {
    guard enabled else {
      return
    }

    logger.debug("Pusher \(message, privacy: .public)")
    print("Pusher \(message)")
  }

  public static func w(_ message: String) {
    guard enabled else {
      return
    }

    logger.warning("Pusher \(message, privacy: .public)")
    print("Pusher WARN \(message)")
  }

  public static func e(_ message: String) {
    logger.error("Pusher \(message, privacy: .public)")
    print("Pusher ERR \(message)")
  }
}
