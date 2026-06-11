import 'package:dio/dio.dart';
import '../models/vehicle.dart';
import 'api.dart';

class VehicleService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<Vehicle>> getVehicles() async {
    final resp = await _dio.get('/vehicles');
    final data = (resp.data['data'] ?? resp.data) as List<dynamic>;
    return data.map((e) => Vehicle.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Vehicle> createVehicle({
    required String plate,
    String make = '',
    String model = '',
    int year = 0,
    String color = '',
  }) async {
    final resp = await _dio.post('/vehicles', data: {
      'plate': plate,
      'make': make,
      'model': model,
      'year': year,
      'color': color,
    });
    return Vehicle.fromJson((resp.data['data'] ?? resp.data) as Map<String, dynamic>);
  }

  Future<void> deleteVehicle(String id) async {
    await _dio.delete('/vehicles/$id');
  }

  Future<Map<String, dynamic>?> lookupByPlate(String plate) async {
    try {
      final resp = await _dio.get('/vehicles/lookup/$plate');
      return (resp.data['data'] ?? resp.data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
