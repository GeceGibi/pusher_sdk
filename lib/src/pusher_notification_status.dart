/// Receipt status for notification delivery / open.
///
/// Wire value is [id]. Use with `Pusher.receipt`, e.g. `status: .opened`.
enum PusherNotificationStatus {
  /// Device received the notification.
  delivered(1),

  /// User opened the notification.
  opened(2);

  new(this.id);

  /// Integer sent on the stats receipt body.
  final int id;
}
