import Foundation
import os

/// Shared logger for native Pusher diagnostics.
///
/// Filter Console / device logs for subsystem `tr.pusher.sdk` or message prefix `Pusher`.
///
/// `d` / `w` respect `enabled` (from Flutter `enableLogs`). `e` always logs.
enum PusherLog {
  private static let logger = Logger(subsystem: "tr.pusher.sdk", category: "Pusher")

  /// Non-error diagnostics. Synced from defaults on init / NSE.
  static var enabled: Bool = false

  static func d(_ message: String) {
    guard enabled else {
      return
    }

    logger.debug("Pusher \(message, privacy: .public)")
    print("Pusher \(message)")
  }

  static func w(_ message: String) {
    guard enabled else {
      return
    }

    logger.warning("Pusher \(message, privacy: .public)")
    print("Pusher WARN \(message)")
  }

  static func e(_ message: String) {
    logger.error("Pusher \(message, privacy: .public)")
    print("Pusher ERR \(message)")
  }
}
