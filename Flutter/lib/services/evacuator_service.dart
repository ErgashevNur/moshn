import 'package:dio/dio.dart';
import '../models/evacuator.dart';
import 'api.dart';

class EvacuatorService {
  final Dio _dio = ApiClient.instance.dio;

  Future<Evacuator> createProfile({
    required String fullName,
    String phone = '',
    String vehiclePlate = '',
  }) async {
    final resp = await _dio.post('/evacuators/profile', data: {
      'full_name': fullName,
      'phone': phone,
      'vehicle_plate': vehiclePlate,
    });
    return Evacuator.fromJson((resp.data['data'] ?? resp.data) as Map<String, dynamic>);
  }

  Future<Evacuator> getProfile() async {
    final resp = await _dio.get('/evacuators/profile');
    return Evacuator.fromJson((resp.data['data'] ?? resp.data) as Map<String, dynamic>);
  }

  Future<void> updateLocation(double lat, double lng) async {
    await _dio.put('/evacuators/location', data: {'lat': lat, 'lng': lng});
  }

  Future<Evacuator> setAvailability(bool isAvailable) async {
    final resp = await _dio.put('/evacuators/availability', data: {'is_available': isAvailable});
    return Evacuator.fromJson((resp.data['data'] ?? resp.data) as Map<String, dynamic>);
  }
}
