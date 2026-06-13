import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show VoidCallback, kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  /// Token yangilash muvaffaqiyatsiz bo'lganda chaqiriladi (login ekraniga yo'naltirish uchun).
  VoidCallback? onUnauthorized;

  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: false,
      responseHeader: false,
      error: true,
    ));
    _dio.interceptors.add(_authInterceptor());
  }

  static final ApiClient instance = ApiClient._();
  late final Dio _dio;
  Dio get dio => _dio;

  static const _storage = FlutterSecureStorage();
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  /// Backend ulanish manzili.
  /// Production APK uchun to'liq URL bering (HTTPS bilan):
  ///   `--dart-define=API_BASE_URL=https://moshn.uz/v1`
  /// Lokal test uchun host/port:
  ///   `--dart-define=API_HOST=192.168.50.2`  (LAN IP)
  /// Hech narsa berilmasa — emulator/web standartlari.
  static const _baseOverride = String.fromEnvironment('API_BASE_URL');
  static const _hostOverride = String.fromEnvironment('API_HOST');
  static const _portOverride = String.fromEnvironment('API_PORT', defaultValue: '8080');

  static const _ngrokUrl = 'https://snore-likewise-aground.ngrok-free.dev';

  static String get baseUrl {
    if (_baseOverride.isNotEmpty) return _baseOverride;
    if (_hostOverride.isNotEmpty) {
      return 'http://$_hostOverride:$_portOverride/v1';
    }
    if (kIsWeb) return 'http://localhost:8080/v1';
    return '$_ngrokUrl/v1';
  }

  Future<String?> get accessToken => _storage.read(key: _accessKey);
  Future<String?> get refreshToken => _storage.read(key: _refreshKey);

  Future<void> saveTokens({required String access, required String refresh}) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }

  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await accessToken;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        if (e.response?.statusCode == 401 &&
            e.requestOptions.path != '/auth/refresh' &&
            e.requestOptions.path != '/auth/login') {
          final refreshed = await _tryRefresh();
          if (refreshed) {
            final opts = e.requestOptions;
            final token = await accessToken;
            opts.headers['Authorization'] = 'Bearer $token';
            try {
              final resp = await _dio.fetch(opts);
              return handler.resolve(resp);
            } catch (_) {}
          }
        }
        handler.next(e);
      },
    );
  }

  Future<bool> _tryRefresh() async {
    final refresh = await refreshToken;
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final resp = await Dio(BaseOptions(baseUrl: baseUrl)).post(
        '/auth/refresh',
        data: {'refresh_token': refresh},
      );
      final data = resp.data as Map<String, dynamic>;
      await saveTokens(
        access: data['access_token'] as String,
        refresh: data['refresh_token'] as String,
      );
      return true;
    } catch (_) {
      await clearTokens();
      onUnauthorized?.call();
      return false;
    }
  }
}
