// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'inbox_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InboxNotification {

/// Notification title.
 String? get title;/// Notification body.
 String? get body;/// Optional image URL.
 String? get image;
/// Create a copy of InboxNotification
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InboxNotificationCopyWith<InboxNotification> get copyWith => _$InboxNotificationCopyWithImpl<InboxNotification>(this as InboxNotification, _$identity);

  /// Serializes this InboxNotification to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as InboxNotification;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InboxNotification&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.body, _this.body) || other.body == _this.body)&&(identical(other.image, _this.image) || other.image == _this.image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as InboxNotification;
  return Object.hash(runtimeType,_this.title,_this.body,_this.image);
}

@override
String toString() {
  final _this = this as InboxNotification;
  return 'InboxNotification(title: ${_this.title}, body: ${_this.body}, image: ${_this.image})';
}


}

/// @nodoc
abstract mixin class $InboxNotificationCopyWith<$Res>  {
  factory $InboxNotificationCopyWith(InboxNotification value, $Res Function(InboxNotification) _then) = _$InboxNotificationCopyWithImpl;
@useResult
$Res call({
 String? title, String? body, String? image
});




}
/// @nodoc
class _$InboxNotificationCopyWithImpl<$Res>
    implements $InboxNotificationCopyWith<$Res> {
  _$InboxNotificationCopyWithImpl(this._self, this._then);

  final InboxNotification _self;
  final $Res Function(InboxNotification) _then;

/// Create a copy of InboxNotification
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = freezed,Object? body = freezed,Object? image = freezed,}) {
  return _then(InboxNotification(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [InboxNotification].
extension InboxNotificationPatterns on InboxNotification {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InboxNotification value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InboxNotification() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InboxNotification value)  $default,){
final _that = this;
switch (_that) {
case _InboxNotification():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InboxNotification value)?  $default,){
final _that = this;
switch (_that) {
case _InboxNotification() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? title,  String? body,  String? image)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InboxNotification() when $default != null:
return $default(_that.title,_that.body,_that.image);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? title,  String? body,  String? image)  $default,) {final _that = this;
switch (_that) {
case _InboxNotification():
return $default(_that.title,_that.body,_that.image);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? title,  String? body,  String? image)?  $default,) {final _that = this;
switch (_that) {
case _InboxNotification() when $default != null:
return $default(_that.title,_that.body,_that.image);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InboxNotification implements InboxNotification {
  const _InboxNotification({this.title, this.body, this.image});
  factory _InboxNotification.fromJson(Map<String, dynamic> json) => _$InboxNotificationFromJson(json);

/// Notification title.
@override final  String? title;
/// Notification body.
@override final  String? body;
/// Optional image URL.
@override final  String? image;

/// Create a copy of InboxNotification
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InboxNotificationCopyWith<_InboxNotification> get copyWith => __$InboxNotificationCopyWithImpl<_InboxNotification>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InboxNotificationToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InboxNotification&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,title,body,image);
}

@override
String toString() {
    return 'InboxNotification(title: $title, body: $body, image: $image)';
}


}

/// @nodoc
abstract mixin class _$InboxNotificationCopyWith<$Res> implements $InboxNotificationCopyWith<$Res> {
  factory _$InboxNotificationCopyWith(_InboxNotification value, $Res Function(_InboxNotification) _then) = __$InboxNotificationCopyWithImpl;
@override @useResult
$Res call({
 String? title, String? body, String? image
});




}
/// @nodoc
class __$InboxNotificationCopyWithImpl<$Res>
    implements _$InboxNotificationCopyWith<$Res> {
  __$InboxNotificationCopyWithImpl(this._self, this._then);

  final _InboxNotification _self;
  final $Res Function(_InboxNotification) _then;

/// Create a copy of InboxNotification
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = freezed,Object? body = freezed,Object? image = freezed,}) {
  return _then(_InboxNotification(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$InboxItem {

/// Notification id.
 String get nid;/// When the notification was sent (UTC).
 DateTime get sentAt;/// Topic key when the send targeted a topic.
 String? get topic;/// Visible notification payload, when present.
@JsonKey(fromJson: _notificationFromJson) InboxNotification? get notification;/// Custom data map from the send.
@JsonKey(fromJson: _stringKeyedMap) Map<String, dynamic> get data;
/// Create a copy of InboxItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InboxItemCopyWith<InboxItem> get copyWith => _$InboxItemCopyWithImpl<InboxItem>(this as InboxItem, _$identity);

  /// Serializes this InboxItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as InboxItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InboxItem&&(identical(other.nid, _this.nid) || other.nid == _this.nid)&&(identical(other.sentAt, _this.sentAt) || other.sentAt == _this.sentAt)&&(identical(other.topic, _this.topic) || other.topic == _this.topic)&&(identical(other.notification, _this.notification) || other.notification == _this.notification)&&const DeepCollectionEquality().equals(other.data, _this.data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as InboxItem;
  return Object.hash(runtimeType,_this.nid,_this.sentAt,_this.topic,_this.notification,const DeepCollectionEquality().hash(_this.data));
}

@override
String toString() {
  final _this = this as InboxItem;
  return 'InboxItem(nid: ${_this.nid}, sentAt: ${_this.sentAt}, topic: ${_this.topic}, notification: ${_this.notification}, data: ${_this.data})';
}


}

/// @nodoc
abstract mixin class $InboxItemCopyWith<$Res>  {
  factory $InboxItemCopyWith(InboxItem value, $Res Function(InboxItem) _then) = _$InboxItemCopyWithImpl;
@useResult
$Res call({
 String nid, DateTime sentAt, String? topic,@JsonKey(fromJson: _notificationFromJson) InboxNotification? notification,@JsonKey(fromJson: _stringKeyedMap) Map<String, dynamic> data
});


$InboxNotificationCopyWith<$Res>? get notification;

}
/// @nodoc
class _$InboxItemCopyWithImpl<$Res>
    implements $InboxItemCopyWith<$Res> {
  _$InboxItemCopyWithImpl(this._self, this._then);

  final InboxItem _self;
  final $Res Function(InboxItem) _then;

/// Create a copy of InboxItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? nid = null,Object? sentAt = null,Object? topic = freezed,Object? notification = freezed,Object? data = null,}) {
  return _then(InboxItem(
nid: null == nid ? _self.nid : nid // ignore: cast_nullable_to_non_nullable
as String,sentAt: null == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime,topic: freezed == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String?,notification: freezed == notification ? _self.notification : notification // ignore: cast_nullable_to_non_nullable
as InboxNotification?,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}
/// Create a copy of InboxItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InboxNotificationCopyWith<$Res>? get notification {
    if (_self.notification == null) {
    return null;
  }

  return $InboxNotificationCopyWith<$Res>(_self.notification!, (value) {
    return _then(_self.copyWith(notification: value));
  });
}
}


/// Adds pattern-matching-related methods to [InboxItem].
extension InboxItemPatterns on InboxItem {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InboxItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InboxItem() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InboxItem value)  $default,){
final _that = this;
switch (_that) {
case _InboxItem():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InboxItem value)?  $default,){
final _that = this;
switch (_that) {
case _InboxItem() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String nid,  DateTime sentAt,  String? topic, @JsonKey(fromJson: _notificationFromJson)  InboxNotification? notification, @JsonKey(fromJson: _stringKeyedMap)  Map<String, dynamic> data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InboxItem() when $default != null:
return $default(_that.nid,_that.sentAt,_that.topic,_that.notification,_that.data);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String nid,  DateTime sentAt,  String? topic, @JsonKey(fromJson: _notificationFromJson)  InboxNotification? notification, @JsonKey(fromJson: _stringKeyedMap)  Map<String, dynamic> data)  $default,) {final _that = this;
switch (_that) {
case _InboxItem():
return $default(_that.nid,_that.sentAt,_that.topic,_that.notification,_that.data);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String nid,  DateTime sentAt,  String? topic, @JsonKey(fromJson: _notificationFromJson)  InboxNotification? notification, @JsonKey(fromJson: _stringKeyedMap)  Map<String, dynamic> data)?  $default,) {final _that = this;
switch (_that) {
case _InboxItem() when $default != null:
return $default(_that.nid,_that.sentAt,_that.topic,_that.notification,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InboxItem implements InboxItem {
  const _InboxItem({required this.nid, required this.sentAt, this.topic, @JsonKey(fromJson: _notificationFromJson) this.notification, @JsonKey(fromJson: _stringKeyedMap)  Map<String, dynamic> data = const <String, dynamic>{}}): _data = data;
  factory _InboxItem.fromJson(Map<String, dynamic> json) => _$InboxItemFromJson(json);

/// Notification id.
@override final  String nid;
/// When the notification was sent (UTC).
@override final  DateTime sentAt;
/// Topic key when the send targeted a topic.
@override final  String? topic;
/// Visible notification payload, when present.
@override@JsonKey(fromJson: _notificationFromJson) final  InboxNotification? notification;
/// Custom data map from the send.
 final  Map<String, dynamic> _data;
/// Custom data map from the send.
@override@JsonKey(fromJson: _stringKeyedMap) Map<String, dynamic> get data {
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_data);
}


/// Create a copy of InboxItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InboxItemCopyWith<_InboxItem> get copyWith => __$InboxItemCopyWithImpl<_InboxItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InboxItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InboxItem&&(identical(other.nid, nid) || other.nid == nid)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.notification, notification) || other.notification == notification)&&const DeepCollectionEquality().equals(other.data, _data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,nid,sentAt,topic,notification,const DeepCollectionEquality().hash(_data));
}

@override
String toString() {
    return 'InboxItem(nid: $nid, sentAt: $sentAt, topic: $topic, notification: $notification, data: $data)';
}


}

/// @nodoc
abstract mixin class _$InboxItemCopyWith<$Res> implements $InboxItemCopyWith<$Res> {
  factory _$InboxItemCopyWith(_InboxItem value, $Res Function(_InboxItem) _then) = __$InboxItemCopyWithImpl;
@override @useResult
$Res call({
 String nid, DateTime sentAt, String? topic,@JsonKey(fromJson: _notificationFromJson) InboxNotification? notification,@JsonKey(fromJson: _stringKeyedMap) Map<String, dynamic> data
});


@override $InboxNotificationCopyWith<$Res>? get notification;

}
/// @nodoc
class __$InboxItemCopyWithImpl<$Res>
    implements _$InboxItemCopyWith<$Res> {
  __$InboxItemCopyWithImpl(this._self, this._then);

  final _InboxItem _self;
  final $Res Function(_InboxItem) _then;

/// Create a copy of InboxItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? nid = null,Object? sentAt = null,Object? topic = freezed,Object? notification = freezed,Object? data = null,}) {
  return _then(_InboxItem(
nid: null == nid ? _self.nid : nid // ignore: cast_nullable_to_non_nullable
as String,sentAt: null == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime,topic: freezed == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String?,notification: freezed == notification ? _self.notification : notification // ignore: cast_nullable_to_non_nullable
as InboxNotification?,data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

/// Create a copy of InboxItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InboxNotificationCopyWith<$Res>? get notification {
    if (_self.notification == null) {
    return null;
  }

  return $InboxNotificationCopyWith<$Res>(_self.notification!, (value) {
    return _then(_self.copyWith(notification: value));
  });
}
}

// dart format on
