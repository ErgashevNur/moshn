import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api.dart';
import '../services/auth_service.dart';
import '../services/ws_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;
  final bool loading;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
    this.loading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
    bool? loading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
      loading: loading ?? this.loading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  final AuthService _service = AuthService();

  Future<void> initialize() async {
    final token = await ApiClient.instance.accessToken;
    if (token == null || token.isEmpty) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final user = await _service.me();
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      await ApiClient.instance.clearTokens();
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _service.login(identifier: email, password: password);
      await ApiClient.instance.saveTokens(
        access: result.access,
        refresh: result.refresh,
      );
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.user,
        loading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: _errMsg(e));
      return false;
    }
  }

  /// Creates the account and immediately authenticates — MVP skips OTP.
  Future<bool> register({
    required String phone,
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _service.register(
        phone: phone,
        email: email,
        password: password,
        name: name,
        role: role,
      );

      await ApiClient.instance.saveTokens(
        access: result.access,
        refresh: result.refresh,
      );
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.user,
        loading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: _errMsg(e));
      return false;
    }
  }

  /// Called after OTP verification — marks user as authenticated.
  void setAuthenticated(User user) {
    state = AuthState(
      status: AuthStatus.authenticated,
      user: user,
    );
  }

  Future<void> refreshUser() async {
    try {
      final user = await _service.me();
      state = state.copyWith(user: user);
    } catch (_) {}
  }

  Future<void> logout() async {
    WsService.instance.disconnect();
    await ApiClient.instance.clearTokens();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  String _errMsg(Object e) {
    if (e is DioException) {
      // Ошибка подключения / таймаут
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return 'Ошибка подключения к серверу. Проверьте интернет или Wi-Fi.';
      }
      // Сообщение, возвращённое backend'ом
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final msg = data['message'];
        if (msg is String && msg.isNotEmpty) return msg;
        if (msg is List && msg.isNotEmpty) return msg.join(', ');
      }
      if (e.response?.statusCode == 401) return 'Неверный email или пароль';
      if (e.response?.statusCode == 400) return 'Неверные данные';
      if (e.response?.statusCode == 409) return 'Этот пользователь уже существует';
    }
    return e.toString();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
