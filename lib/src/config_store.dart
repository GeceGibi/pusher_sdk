import 'package:shared_preferences/shared_preferences.dart';

/// Persists SDK config so the FCM background isolate can reload it.
class SdkConfig {
  /// Binds [projectId], [statsKey], and [baseUrl].
  const new({
    required this.projectId,
    required this.statsKey,
    required this.baseUrl,
  });

  /// Pusher project ObjectId hex.
  final String projectId;

  /// Per-project stats key from the pusher.tr panel.
  final String statsKey;

  /// Stats host without trailing slash.
  final String baseUrl;
}

/// SharedPreferences keys for [SdkConfig].
abstract final class ConfigStore {
  /// Preference key for project id.
  static const projectIdKey = 'pusher_sdk.project_id';

  /// Preference key for the project stats key.
  static const statsKeyKey = 'pusher_sdk.stats_key';

  /// Preference key for base URL.
  static const baseUrlKey = 'pusher_sdk.base_url';

  /// Writes [config] for later isolate reloads.
  static Future<void> save(SdkConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(projectIdKey, config.projectId);
    await prefs.setString(statsKeyKey, config.statsKey);
    await prefs.setString(baseUrlKey, config.baseUrl);
  }

  /// Loads a previously saved config, or null.
  static Future<SdkConfig?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final projectId = prefs.getString(projectIdKey)?.trim();
    final statsKey = prefs.getString(statsKeyKey)?.trim();
    final baseUrl = prefs.getString(baseUrlKey)?.trim();

    if (projectId == null ||
        projectId.isEmpty ||
        statsKey == null ||
        statsKey.isEmpty) {
      return null;
    }

    return SdkConfig(
      projectId: projectId,
      statsKey: statsKey,
      baseUrl: (baseUrl == null || baseUrl.isEmpty)
          ? 'https://stats.pusher.tr'
          : baseUrl,
    );
  }
}
