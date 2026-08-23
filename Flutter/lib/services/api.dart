import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, kReleaseMode;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: false,
          responseHeader: false,
          error: true,
        ),
      );
    }
    _dio.interceptors.add(_authInterceptor());
  }

  static final ApiClient instance = ApiClient._();
  late final Dio _dio;
  Dio get dio => _dio;

  static const _storage = FlutterSecureStorage();
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  // Secure storage reads go through a platform channel on every call, which
  // adds latency to every request. Cache the access token in memory once
  // read so subsequent requests don't pay that cost.
  String? _accessTokenCache;
  bool _accessTokenLoaded = false;

  /// Адрес подключения к backend'у.
  /// Для production APK укажите полный URL (с HTTPS):
  ///   `--dart-define=API_BASE_URL=https://pitgo.uz/v1`
  /// Для локального теста — host/port:
  ///   `--dart-define=API_HOST=192.168.50.2`  (LAN IP)
  /// Если ничего не указано — стандарты эмулятора/веба.
  static const _baseOverride = String.fromEnvironment('API_BASE_URL');
  static const _hostOverride = String.fromEnvironment('API_HOST');
  static const _portOverride = String.fromEnvironment(
    'API_PORT',
    defaultValue: '8080',
  );

  static const _ngrokUrl = 'https://snore-likewise-aground.ngrok-free.dev';
  static const _prodUrl = 'https://api.pitgo.uz';

  static String get baseUrl {
    if (_baseOverride.isNotEmpty) return _baseOverride;
    if (_hostOverride.isNotEmpty) {
      return 'http://$_hostOverride:$_portOverride/v1';
    }
    if (kIsWeb) return 'http://localhost:8080/v1';
    // Release build (APK/App Store) — --dart-define unutilsa ham productionga
    // (o'lik ngrok tunneliga emas) ulanadi. Faqat debug/profile rejimida,
    // --dart-define berilmasa, dev ngrok tunneliga tushadi.
    if (kReleaseMode) return '$_prodUrl/v1';
    return '$_ngrokUrl/v1';
  }

  /// Serverdagi fayl yo'lini (`/uploads/vehicles/xxx.jpg`) to'liq URL'ga
  /// aylantiradi. Yuklamalar `/v1` siz beriladi (`useStaticAssets`, main.ts),
  /// shuning uchun bazadan `/v1` qirqiladi.
  /// Bo'sh yoki allaqachon to'liq URL bo'lsa — o'zgartirmaydi.
  static String mediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final origin = baseUrl.endsWith('/v1')
        ? baseUrl.substring(0, baseUrl.length - 3)
        : baseUrl;
    final sep = path.startsWith('/') ? '' : '/';
    return '$origin$sep$path';
  }

  Future<String?> get accessToken async {
    if (_accessTokenLoaded) return _accessTokenCache;
    _accessTokenCache = await _storage.read(key: _accessKey);
    _accessTokenLoaded = true;
    return _accessTokenCache;
  }

  Future<String?> get refreshToken => _storage.read(key: _refreshKey);

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    _accessTokenCache = access;
    _accessTokenLoaded = true;
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<void> clearTokens() async {
    _accessTokenCache = null;
    _accessTokenLoaded = true;
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

  // The app fires several parallel requests per screen. If the access token
  // expires, they all hit 401 at once — without single-flighting, each would
  // independently race to refresh, and a transient failure in a later racer
  // would wipe out the valid tokens an earlier racer just saved. Concurrent
  // callers now await the same in-flight refresh instead.
  Future<bool>? _refreshFuture;

  Future<bool> _tryRefresh() {
    return _refreshFuture ??= _doRefresh().whenComplete(() {
      _refreshFuture = null;
    });
  }

  Future<bool> _doRefresh() async {
    final refresh = await refreshToken;
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final resp = await Dio(
        BaseOptions(baseUrl: baseUrl),
      ).post('/auth/refresh', data: {'refresh_token': refresh});
      final data = resp.data as Map<String, dynamic>;
      await saveTokens(
        access: data['access_token'] as String,
        refresh: data['refresh_token'] as String,
      );
      return true;
    } catch (_) {
      await clearTokens();
      return false;
    }
  }
}
