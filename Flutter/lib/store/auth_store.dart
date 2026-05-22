import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api.dart';
import '../services/auth_service.dart';

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
      final result = await _service.login(email: email, password: password);
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

  Future<void> logout() async {
    await ApiClient.instance.clearTokens();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  String _errMsg(Object e) => e.toString();
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
