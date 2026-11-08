import 'package:freezed_annotation/freezed_annotation.dart';

part 'inbox_item.freezed.dart';
part 'inbox_item.g.dart';

Map<String, dynamic> _stringKeyedMap(Object? value) {
  if (value is! Map) {
    return const {};
  }
  return Map<String, dynamic>.from(value);
}

InboxNotification? _notificationFromJson(Object? value) {
  if (value is! Map) {
    return null;
  }
  return InboxNotification.fromJson(Map<String, dynamic>.from(value));
}

/// FCM `notification` block on an inbox row.
@freezed
abstract class InboxNotification with _$InboxNotification {
  /// Creates a notification payload.
  const factory({
    /// Notification title.
    String? title,

    /// Notification body.
    String? body,

    /// Optional image URL.
    String? image,
  }) = _InboxNotification;

  /// Deserializes from JSON.
  factory fromJson(Map<String, dynamic> json) =>
      _$InboxNotificationFromJson(json);
}

/// One row from `GET .../notifications/inbox/<clientId>`.
@freezed
abstract class InboxItem with _$InboxItem {
  /// Creates an inbox item.
  const factory({
    /// Notification id.
    required String nid,

    /// When the notification was sent (UTC).
    required DateTime sentAt,

    /// Topic key when the send targeted a topic.
    String? topic,

    /// Visible notification payload, when present.
    @JsonKey(fromJson: _notificationFromJson) InboxNotification? notification,

    /// Custom data map from the send.
    @JsonKey(fromJson: _stringKeyedMap)
    @Default(<String, dynamic>{})
    Map<String, dynamic> data,
  }) = _InboxItem;

  /// Deserializes from JSON.
  factory fromJson(Map<String, dynamic> json) => _$InboxItemFromJson(json);
}
