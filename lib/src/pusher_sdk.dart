import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_helpers/device_helpers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:pusher_sdk/src/config_store.dart';
import 'package:pusher_sdk/src/device_id.dart';
import 'package:pusher_sdk/src/hmac_sign.dart';

/// Flutter client for stats.pusher.tr.
///
/// Call [init] once with project keys. It persists config, attaches foreground
/// FCM listeners, and posts device hello. From the host background handler,
/// optionally await [onBackgroundMessage] when you want delivered receipts
/// (config is reloaded from SharedPreferences in that isolate).
abstract final class PusherSdk {
  /// Delivered receipt status.
  static const statusDelivered = 1;

  /// Opened receipt status.
  static const statusOpened = 2;

  static String? _projectId;
  static String? _statsKey;
  static String _baseUrl = 'https://stats.pusher.tr';
  static bool _attached = false;
  static String? _deviceId;

  /// True when config and device id are loaded in this isolate.
  static bool get isInitialized {
    return _projectId != null && _statsKey != null && _deviceId != null;
  }

  /// Stable install id from SharedPreferences.
  static String? get deviceId => _deviceId;

  /// Loads keys, attaches foreground listeners, and posts device hello.
  ///
  /// Does not register an FCM background handler — call [onBackgroundMessage]
  /// from the host handler when delivered receipts in background are wanted.
  static Future<void> init({
    required String projectId,
    required String statsKey,
    String baseUrl = 'https://stats.pusher.tr',
  }) async {
    final pid = projectId.trim();
    final key = statsKey.trim();
    final host = baseUrl.replaceAll(RegExp(r'/+$'), '');

    if (pid.isEmpty) {
      throw ArgumentError.value(projectId, 'projectId', 'required');
    }

    if (key.isEmpty) {
      throw ArgumentError.value(statsKey, 'statsKey', 'required');
    }

    final config = SdkConfig(
      projectId: pid,
      statsKey: key,
      baseUrl: host,
    );
    await ConfigStore.save(config);
    await _apply(config);
    attach();
    await hello();
  }

  /// Applies [config] and loads the device id into this isolate.
  static Future<void> _apply(SdkConfig config) async {
    _projectId = config.projectId;
    _statsKey = config.statsKey;
    _baseUrl = config.baseUrl;
    _deviceId = await DeviceIdStore.resolve();
  }

  /// Reloads config from SharedPreferences when this isolate is cold.
  static Future<void> _ensureReady() async {
    if (isInitialized) {
      return;
    }

    final config = await ConfigStore.load();

    if (config == null) {
      throw StateError('Call PusherSdk.init before use');
    }

    await _apply(config);
  }

  /// Foreground delivered + notification-open listeners.
  ///
  /// Called from [init]. Safe to call again; no-op if already attached.
  static void attach() {
    if (!isInitialized) {
      throw StateError('Call PusherSdk.init before attach');
    }

    if (_attached) {
      return;
    }

    _attached = true;

    FirebaseMessaging.onMessage.listen((message) {
      unawaited(_receiptFromMessage(message, statusDelivered));
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      unawaited(_receiptFromMessage(message, statusOpened));
    });

    unawaited(_openFromTerminated());
  }

  /// Opened from a cold start (tap while terminated).
  static Future<void> _openFromTerminated() async {
    final initial = await FirebaseMessaging.instance.getInitialMessage();

    if (initial != null) {
      await _receiptFromMessage(initial, statusOpened);
    }
  }

  /// Optional host background handler hook. Posts delivered when `data.nid` is set.
  ///
  /// ```dart
  /// @pragma('vm:entry-point')
  /// Future<void> onBg(RemoteMessage m) async {
  ///   await Firebase.initializeApp();
  ///   await PusherSdk.onBackgroundMessage(m);
  /// }
  /// ```
  static Future<void> onBackgroundMessage(RemoteMessage message) async {
    await _receiptFromMessage(message, statusDelivered);
  }

  /// Posts device hello. Optional FCM [token] when available.
  ///
  /// Called from [init]. Uses [DeviceHelpers] for `os_version` and `app_version`.
  static Future<void> hello({String? token}) async {
    await _ensureReady();

    final platform = _platform();

    if (platform == null) {
      return;
    }

    final resolvedToken = token ?? await _fcmToken();
    final device = await _deviceInfo();
    final body = <String, dynamic>{
      'device_id': _deviceId,
      'platform': platform,
      'locale': Platform.localeName,
      'token': ?resolvedToken,
      'os_version': ?device?.osVersion,
      'app_version': ?device?.appVersion,
    };

    await _post(path: '/$_projectId/hi', body: body);
  }

  /// Upserts the FCM token on the stats device row (via [hello]).
  ///
  /// Optional. Pass [token], or the SDK reads the current FCM token.
  /// Call again when the token refreshes so the panel can target this device.
  static Future<void> syncToken({String? token}) async {
    final trimmed = token?.trim();
    final value = (trimmed != null && trimmed.isNotEmpty)
        ? trimmed
        : await _fcmToken();

    if (value == null || value.isEmpty) {
      return;
    }

    await hello(token: value);
  }

  /// Posts one receipt. [status] is [statusDelivered] or [statusOpened].
  static Future<void> receipt({
    required String nid,
    required int status,
  }) async {
    await _ensureReady();

    final trimmed = nid.trim();

    if (trimmed.isEmpty) {
      return;
    }

    if (status != statusDelivered && status != statusOpened) {
      return;
    }

    final platform = _platform();

    if (platform == null) {
      return;
    }

    final body = <String, dynamic>{
      'device_id': _deviceId,
      'platform': platform,
      'status': status,
      'locale': Platform.localeName,
    };

    await _post(path: '/$_projectId/n/$trimmed', body: body);
  }

  /// Delivered / opened from an FCM [message] when `data.nid` is present.
  static Future<void> _receiptFromMessage(
    RemoteMessage message,
    int status,
  ) async {
    try {
      await _ensureReady();
      final nid = message.data['nid']?.toString().trim();

      if (nid == null || nid.isEmpty) {
        return;
      }

      await receipt(nid: nid, status: status);
    } on Object {
      // Receipts must not crash the host app or background isolate.
    }
  }

  /// Signed JSON POST. Path is what the Dart stats process sees (no `/v1`).
  static Future<void> _post({
    required String path,
    required Map<String, dynamic> body,
  }) async {
    final raw = jsonEncode(body);
    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final signature = HmacSign.signature(
      method: 'POST',
      pathAndQuery: path,
      unixSeconds: timestamp,
      body: raw,
      key: _statsKey!,
    );

    final response = await http.post(
      Uri.parse('$_baseUrl/v1$path'),
      headers: {
        'content-type': 'application/json',
        'x-timestamp': '$timestamp',
        'x-signature': signature,
      },
      body: raw,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'PusherSdk HTTP ${response.statusCode}: ${response.body}',
        uri: response.request?.url,
      );
    }
  }

  /// OS / app fields from [DeviceHelpers], or null on failure.
  static Future<({String? osVersion, String? appVersion})?> _deviceInfo() async {
    try {
      final info = await DeviceHelpers.getInfo();
      final osVersion = info.osVersion.trim();
      final appVersion = info.appVersion.trim();

      return (
        osVersion: osVersion.isEmpty ? null : osVersion,
        appVersion: appVersion.isEmpty ? null : appVersion,
      );
    } on Object {
      return null;
    }
  }

  /// Current FCM token, or null.
  static Future<String?> _fcmToken() async {
    try {
      if (!await FirebaseMessaging.instance.isSupported()) {
        return null;
      }

      final token = await FirebaseMessaging.instance.getToken();

      if (token == null || token.trim().isEmpty) {
        return null;
      }

      return token.trim();
    } on Object {
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
}
