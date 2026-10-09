import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Stable install id in SharedPreferences. Survives most Android id churn.
abstract final class DeviceIdStore {
  /// Preference key for the install UUID.
  static const key = 'pusher_sdk.device_id';

  /// Returns the stored id, or creates and persists a new UUID v4.
  static Future<String> resolve() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(key)?.trim();

    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final created = const Uuid().v4();
    await prefs.setString(key, created);
    return created;
  }
}
