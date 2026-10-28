import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_endpoints.dart';

final apiConfigProvider = StateNotifierProvider<ApiConfigNotifier, String>((ref) {
  return ApiConfigNotifier();
});

class ApiConfigNotifier extends StateNotifier<String> {
  static const _key = 'api_base_url';
  // Single source of truth for the default lives in ApiEndpoints.baseUrl,
  // so it can't drift out of sync with the value used elsewhere in the app.
  static const _defaultUrl = ApiEndpoints.defaultBaseUrl;

  ApiConfigNotifier() : super(_defaultUrl) {
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_key);
    // A URL saved by an older build (the temporary ngrok tunnel) must not
    // override the new AWS default.
    // A URL saved by an older build (the ngrok tunnel or the old AWS server, which
    // does not have the /api/v1 gateway) must not override the new default.
    final isOldTunnel = savedUrl != null &&
        (savedUrl.contains('ngrok-free.dev') || savedUrl.contains('13.63.148.236'));
    if (savedUrl != null && savedUrl.isNotEmpty && !isOldTunnel) {
      state = savedUrl;
      ApiEndpoints.baseUrl = savedUrl;
    } else {
      ApiEndpoints.baseUrl = _defaultUrl;
    }
  }

  Future<void> setBaseUrl(String newUrl) async {
    // Basic cleanup of URL
    String cleanUrl = newUrl.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    if (!cleanUrl.startsWith('http')) {
      // plain IPs / localhost are LAN test servers; named hosts are HTTPS
      final isLan = RegExp(r'^(\d{1,3}\.){3}\d{1,3}|^localhost').hasMatch(cleanUrl);
      cleanUrl = '${isLan ? 'http' : 'https'}://$cleanUrl';
    }
    
    state = cleanUrl;
    ApiEndpoints.baseUrl = cleanUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, cleanUrl);
  }
}
