import 'package:dio/dio.dart';
import '../models/user.dart';
import 'api.dart';

class AuthService {
  final Dio _dio = ApiClient.instance.dio;

  Future<({User user, String access, String refresh})> login({
    required String email,
    required String password,
  }) async {
    final resp = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = resp.data as Map<String, dynamic>;
    final payload = (data['data'] ?? data) as Map<String, dynamic>;
    return _parseAuth(payload);
  }

  /// Registers the user and returns auth tokens directly — MVP skips email OTP.
  Future<({User user, String access, String refresh})> register({
    required String phone,
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    final resp = await _dio.post('/auth/register', data: {
      'phone': phone,
      'email': email,
      'password': password,
      'full_name': name,
      'role': role.name,
      'workshop_address': role == UserRole.mechanic ? 'Ko\'rsatilmagan' : '',
    });
    final data = resp.data as Map<String, dynamic>;
    final payload = (data['data'] ?? data) as Map<String, dynamic>;
    return _parseAuth(payload);
  }

  Future<void> sendOtp(String email) async {
    await _dio.post('/auth/send-otp', data: {'email': email});
  }

  Future<({User user, String access, String refresh})> verifyOtp({
    required String email,
    required String code,
  }) async {
    final resp = await _dio.post('/auth/verify-otp', data: {
      'email': email,
      'code': code,
    });
    final data = resp.data as Map<String, dynamic>;
    final payload = (data['data'] ?? data) as Map<String, dynamic>;
    return _parseAuth(payload);
  }

  Future<User> me() async {
    final resp = await _dio.get('/profile');
    return User.fromJson(resp.data as Map<String, dynamic>);
  }

  ({User user, String access, String refresh}) _parseAuth(Map<String, dynamic> data) {
    return (
      user: User.fromJson(data['user'] as Map<String, dynamic>),
      access: data['access_token'] as String,
      refresh: data['refresh_token'] as String,
    );
  }
}
