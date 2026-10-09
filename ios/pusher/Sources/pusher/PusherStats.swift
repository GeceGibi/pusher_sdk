import Foundation

/// Public entry for the host Notification Service Extension.
@objc public class PusherStats: NSObject {
  /// Posts delivered when `userInfo` carries `nid` (top-level or under `data`).
  /// Call `contentHandler` inside [completion] so the NSE isn't killed early.
  @objc public static func handleNotification(
    _ userInfo: [AnyHashable: Any],
    completion: (() -> Void)? = nil
  ) {
    PusherLog.d("NSE handleNotification")
    PusherClient.receipt(
      fromUserInfo: userInfo,
      status: PusherClient.statusDelivered,
      completion: completion
    )
  }

  /// Posts opened when `userInfo` carries `nid`.
  @objc public static func handleOpened(
    _ userInfo: [AnyHashable: Any],
    completion: (() -> Void)? = nil
  ) {
    PusherLog.d("NSE handleOpened")
    PusherClient.receipt(
      fromUserInfo: userInfo,
      status: PusherClient.statusOpened,
      completion: completion
    )
  }
}
