import 'dart:async';
import 'dart:io';

import 'package:device_helpers/device_helpers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Flutter client for stats.pusher.tr.
///
/// [init] writes keys to native storage, posts device hello via native HTTP,
/// and attaches foreground FCM listeners. Delivered receipts in background
/// come from native (Android C2DM receiver / iOS Notification Service Extension).
abstract final class Pusher {
  /// Delivered receipt status.
  static const statusDelivered = 1;

  /// Opened receipt status.
  static const statusOpened = 2;

  /// Log tag / prefix. Filter: `adb logcat | rg Pusher` or `-s Pusher`.
  static const logTag = 'Pusher';

  static const _channel = MethodChannel('pusher');

  static String? _deviceId;
  static bool _attached = false;
  static bool _initialized = false;

  /// True after a successful [init] in this isolate.
  static bool get isInitialized => _initialized;

  /// Stable install id from native storage.
  static String? get deviceId => _deviceId;

  /// Loads keys into native, posts hello, attaches foreground listeners.
  ///
  /// Host only passes [projectId] and [statsKey]. Stats host and iOS App Group
  /// (`group.<mainBundleId>`) are fixed by the plugin — see README for NSE setup.
  static Future<void> init({
    required String projectId,
    required String statsKey,
  }) async {
    final pid = projectId.trim();
    final key = statsKey.trim();

    if (pid.isEmpty) {
      throw ArgumentError.value(projectId, 'projectId', 'required');
    }

    if (key.isEmpty) {
      throw ArgumentError.value(statsKey, 'statsKey', 'required');
    }

    if (_platform() == null) {
      _log('init skip: unsupported platform');
      return;
    }

    _log('init start projectId=$pid');

    final args = await _helloArgs(
      projectId: pid,
      statsKey: key,
    );

    final id = await _channel.invokeMethod<String>('init', args);
    _deviceId = id;
    _initialized = true;
    _log('init ok deviceId=$id');
    attach();
  }

  /// Foreground delivered + notification-open listeners.
  ///
  /// Called from [init]. Safe to call again; no-op if already attached.
  static void attach() {
    if (!_initialized) {
      throw StateError('Call Pusher.init before attach');
    }

    if (_attached) {
      _log('attach skip: already attached');
      return;
    }

    _attached = true;
    _log('attach listeners');

    FirebaseMessaging.onMessage.listen((message) {
      _log('onMessage data=${message.data}');
      unawaited(_receiptFromMessage(message, statusDelivered));
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _log('onMessageOpenedApp data=${message.data}');
      unawaited(_receiptFromMessage(message, statusOpened));
    });

    unawaited(_openFromTerminated());
  }

  /// Opened from a cold start (tap while terminated).
  static Future<void> _openFromTerminated() async {
    final initial = await FirebaseMessaging.instance.getInitialMessage();

    if (initial != null) {
      _log('getInitialMessage data=${initial.data}');
      await _receiptFromMessage(initial, statusOpened);
    } else {
      _log('getInitialMessage null');
    }
  }

  /// Optional Dart fallback for delivered receipts.
  ///
  /// Prefer native Android receiver / iOS NSE. Kept for hosts that still
  /// register `FirebaseMessaging.onBackgroundMessage`.
  static Future<void> onBackgroundMessage(RemoteMessage message) async {
    _log('onBackgroundMessage data=${message.data}');
    await _receiptFromMessage(message, statusDelivered);
  }

  /// Posts device hello via native HTTP.
  static Future<void> hello({String? token}) async {
    if (_platform() == null) {
      _log('hello skip: unsupported platform');
      return;
    }

    final args = await _helloArgs(token: token);
    _log('hello invoke token=${args['token'] != null}');
    await _channel.invokeMethod<void>('hello', args);
  }

  /// Upserts the FCM token on the stats device row (via [hello]).
  static Future<void> syncToken({String? token}) async {
    final trimmed = token?.trim();
    final value = (trimmed != null && trimmed.isNotEmpty)
        ? trimmed
        : await _fcmToken();

    if (value == null || value.isEmpty) {
      _log('syncToken skip: empty token');
      return;
    }

    _log('syncToken');
    await hello(token: value);
  }

  /// Posts one receipt via native HTTP.
  static Future<void> receipt({
    required String nid,
    required int status,
  }) async {
    final trimmed = nid.trim();

    if (trimmed.isEmpty) {
      _log('receipt skip: empty nid');
      return;
    }

    if (status != statusDelivered && status != statusOpened) {
      _log('receipt skip: bad status=$status');
      return;
    }

    if (_platform() == null) {
      _log('receipt skip: unsupported platform');
      return;
    }

    _log('receipt invoke nid=$trimmed status=$status');
    await _channel.invokeMethod<void>('receipt', {
      'nid': trimmed,
      'status': status,
    });
  }

  /// Delivered / opened from an FCM [message] when `data.nid` is present.
  static Future<void> _receiptFromMessage(
    RemoteMessage message,
    int status,
  ) async {
    try {
      final nid = message.data['nid']?.toString().trim();

      if (nid == null || nid.isEmpty) {
        _log('receiptFromMessage skip: no nid keys=${message.data.keys}');
        return;
      }

      await receipt(nid: nid, status: status);
    } on Object catch (error) {
      _log('receiptFromMessage error: $error');
    }
  }

  /// Builds hello/init args. Device fields are omitted when unavailable;
  /// native skips hello in that case but still stores config.
  static Future<Map<String, Object?>> _helloArgs({
    String? projectId,
    String? statsKey,
    String? token,
  }) async {
    final device = await _deviceInfo();
    final resolvedToken = token ?? await _fcmToken();

    _log(
      'helloArgs device=${device != null} '
      'token=${resolvedToken != null} '
      'appVersionCode=${device?.appVersionCode}',
    );

    return {
      'projectId': ?projectId,
      'statsKey': ?statsKey,
      'locale': Platform.localeName,
      'isEmulator': ?device?.isEmulator,
      'debugMode': ?device?.debugMode,
      'appVersionCode': ?device?.appVersionCode,
      'token': ?resolvedToken,
      'osVersion': ?device?.osVersion,
      'appVersion': ?device?.appVersion,
    };
  }

  /// Required hello fields from [DeviceHelpers], or null on failure.
  static Future<
    ({
      bool isEmulator,
      bool debugMode,
      String appVersionCode,
      String? osVersion,
      String? appVersion,
    })?
  >
  _deviceInfo() async {
    try {
      final info = await DeviceHelpers.getInfo();
      final appVersionCode = info.appBuild.trim();

      if (appVersionCode.isEmpty) {
        _log('deviceInfo skip: empty appBuild');
        return null;
      }

      final osVersion = info.osVersion.trim();
      final appVersion = info.appVersion.trim();

      return (
        isEmulator: info.isEmulator,
        debugMode: kDebugMode || info.isDebugMode,
        appVersionCode: appVersionCode,
        osVersion: osVersion.isEmpty ? null : osVersion,
        appVersion: appVersion.isEmpty ? null : appVersion,
      );
    } on Object catch (error) {
      _log('deviceInfo error: $error');
      return null;
    }
  }

  /// Current FCM token, or null.
  static Future<String?> _fcmToken() async {
    try {
      if (!await FirebaseMessaging.instance.isSupported()) {
        _log('fcmToken skip: unsupported');
        return null;
      }

      final token = await FirebaseMessaging.instance.getToken();

      if (token == null || token.trim().isEmpty) {
        _log('fcmToken skip: empty');
        return null;
      }

      return token.trim();
    } on Object catch (error) {
      _log('fcmToken error: $error');
      return null;
    }
  }

  /// `android` / `ios`. Null skips the request on other hosts.
  static String? _platform() {
    if (Platform.isAndroid) {
      return 'android';
    }

    if (Platform.isIOS) {
      return 'ios';
    }

    return null;
  }

  static void _log(String message) {
    debugPrint('$logTag $message');
  }
}
