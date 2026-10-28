import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_endpoints.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';

  /// Called after the server answers 401 on a protected call (token expired,
  /// invalid, or the account no longer exists). The auth provider sets this to
  /// sign the user out and show the login screen.
  static void Function()? onUnauthorized;

  /// A wrong password also returns 401, so the public auth routes must never
  /// be treated as "session expired".
  static bool _isPublic(String path) =>
      RegExp(r'/auth/(register|login|google|reset-password)$').hasMatch(path);

  /// AI, label/barcode photo and meal-plan calls can take several seconds.
  static bool _isSlow(String path) => RegExp(
          r'/(ai/|ocr/upload|barcode/scan-image|meal-plans/generate|recipes/generate-instructions)')
      .hasMatch(path);

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.baseUrl = ApiEndpoints.baseUrl;
          if (_isSlow(options.path)) {
            options.receiveTimeout = const Duration(seconds: 60);
          }
          if (!_isPublic(options.path)) {
            final token = await getToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final path = error.requestOptions.path;
          if (error.response?.statusCode == 401 && !_isPublic(path)) {
            await clearToken();
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}

/// The server's message for a failed call, or null when there is none
/// (connection problem, non-JSON error page). Safe on any response body.
String? apiDetail(DioException e) {
  final d = e.response?.data;
  if (d is Map) {
    final detail = d['detail'];
    if (detail is String) return detail;
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map && first['msg'] != null) return first['msg'].toString();
    }
  }
  return null;
}

/// Turns a failed call into one readable message (400/401/403/404/503 carry a
/// string `detail`; 422 carries a list).
String apiErrorMessage(Object e) {
  if (e is DioException) {
    final d = e.response?.data;
    if (d is Map && d['detail'] is String) return d['detail'] as String;
    if (d is Map && d['detail'] is List && (d['detail'] as List).isNotEmpty) {
      final first = (d['detail'] as List).first;
      if (first is Map && first['msg'] != null) return first['msg'].toString();
      return 'Invalid input';
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'Cannot reach the server';
    }
  }
  return 'Something went wrong';
}
