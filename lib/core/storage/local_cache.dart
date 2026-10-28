import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the last-known-good JSON payload for a handful of Home-screen
/// data sources, so the app can still show something meaningful if the
/// backend is unreachable on next launch (instead of a blank/zero state).
/// Not a general offline queue — read-through cache only, refreshed on every
/// successful fetch.
class LocalCache {
  static const _prefix = 'cache_';

  static Future<void> save(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$key', jsonEncode(data));
  }

  /// Returns the cached value (decoded from JSON), or null if nothing was
  /// ever cached for this key.
  static Future<dynamic> load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$key');
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }
}
