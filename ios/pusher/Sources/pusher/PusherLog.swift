import Foundation
import os

/// Shared logger for native Pusher diagnostics.
///
/// Filter Console / device logs for subsystem `tr.pusher.sdk` or message prefix `Pusher`.
enum PusherLog {
  private static let logger = Logger(subsystem: "tr.pusher.sdk", category: "Pusher")

  static func d(_ message: String) {
    logger.debug("Pusher \(message, privacy: .public)")
    print("Pusher \(message)")
  }

  static func w(_ message: String) {
    logger.warning("Pusher \(message, privacy: .public)")
    print("Pusher WARN \(message)")
  }

  static func e(_ message: String) {
    logger.error("Pusher \(message, privacy: .public)")
    print("Pusher ERR \(message)")
  }
}
