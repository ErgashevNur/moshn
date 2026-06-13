import 'package:dio/dio.dart';
import '../models/user.dart';
import 'api.dart';

class AuthService {
  final Dio _dio = ApiClient.instance.dio;

  Future<({User user, String access, String refresh})> login({
    required String identifier,
    required String password,
  }) async {
    final resp = await _dio.post('/auth/login', data: {
      'email': identifier,
      'password': password,
    });
    final payload = (resp.data['data'] ?? resp.data) as Map<String, dynamic>;
    return _parseAuth(payload);
  }

  Future<({User user, String access, String refresh})> register({
    required String phone,
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? shopName,
    String? address,
    double? latitude,
    double? longitude,
    String? workingHours,
    List<String>? serviceTypes,
  }) async {
    final data = <String, dynamic>{
      'phone': phone,
      'email': email,
      'password': password,
      'fullName': name,
      'role': role == UserRole.service ? 'service' : 'owner',
    };
    if (role == UserRole.service) {
      data['shopName'] = shopName ?? '';
      data['address'] = address ?? 'Ko\'rsatilmagan';
      data['latitude'] = latitude ?? 0.0;
      data['longitude'] = longitude ?? 0.0;
      data['workingHours'] = workingHours ?? '';
      data['serviceTypes'] = serviceTypes ?? [];
    }
    final resp = await _dio.post('/auth/register', data: data);
    final payload = (resp.data['data'] ?? resp.data) as Map<String, dynamic>;
    return _parseAuth(payload);
  }

  Future<void> sendOtp(String phone) async {
    await _dio.post('/auth/send-otp', data: {'phone': phone});
  }

  Future<({User user, String access, String refresh})> verifyOtp({
    required String phone,
    required String code,
  }) async {
    final resp = await _dio.post('/auth/verify-otp', data: {
      'phone': phone,
      'code': code,
    });
    final payload = (resp.data['data'] ?? resp.data) as Map<String, dynamic>;
    return _parseAuth(payload);
  }

  Future<User> me() async {
    final resp = await _dio.get('/profile');
    final payload = (resp.data['data'] ?? resp.data) as Map<String, dynamic>;
    return User.fromJson(payload['user'] as Map<String, dynamic>? ?? payload);
  }

  ({User user, String access, String refresh}) _parseAuth(Map<String, dynamic> data) => (
        user: User.fromJson(data['user'] as Map<String, dynamic>),
        access: data['access_token'] as String,
        refresh: data['refresh_token'] as String,
      );
}
