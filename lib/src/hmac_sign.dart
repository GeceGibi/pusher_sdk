import 'dart:convert';

import 'package:crypto/crypto.dart';

/// HMAC-SHA256 request signing for the stats API.
///
/// Canonical text (four lines joined by newline):
/// method, path+query, unix seconds, body.
abstract final class HmacSign {
  /// Base64 digest for [method], [pathAndQuery], [unixSeconds], and [body].
  static String signature({
    required String method,
    required String pathAndQuery,
    required int unixSeconds,
    required String body,
    required String key,
  }) {
    final canonical = [
      method.toUpperCase(),
      pathAndQuery,
      '$unixSeconds',
      body,
    ].join('\n');
    final digest = Hmac(
      sha256,
      utf8.encode(key),
    ).convert(utf8.encode(canonical));

    return base64Encode(digest.bytes);
  }
}
