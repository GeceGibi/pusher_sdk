// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inbox_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InboxNotification _$InboxNotificationFromJson(Map<String, dynamic> json) =>
    _InboxNotification(
      title: json['title'] as String?,
      body: json['body'] as String?,
      image: json['image'] as String?,
    );

Map<String, dynamic> _$InboxNotificationToJson(_InboxNotification instance) =>
    <String, dynamic>{
      'title': instance.title,
      'body': instance.body,
      'image': instance.image,
    };

_InboxItem _$InboxItemFromJson(Map<String, dynamic> json) => _InboxItem(
  nid: json['nid'] as String,
  sentAt: DateTime.parse(json['sentAt'] as String),
  topic: json['topic'] as String?,
  notification: _notificationFromJson(json['notification']),
  data: json['data'] == null
      ? const <String, dynamic>{}
      : _stringKeyedMap(json['data']),
);

Map<String, dynamic> _$InboxItemToJson(_InboxItem instance) =>
    <String, dynamic>{
      'nid': instance.nid,
      'sentAt': instance.sentAt.toIso8601String(),
      'topic': instance.topic,
      'notification': instance.notification,
      'data': instance.data,
    };
