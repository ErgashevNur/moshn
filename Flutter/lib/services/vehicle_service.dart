import 'package:dio/dio.dart';
import '../models/vehicle.dart';
import 'api.dart';

class VehicleService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<Vehicle>> list() async {
    final resp = await _dio.get('/vehicles');
    final data = resp.data as Map<String, dynamic>;
    final list = (data['vehicles'] ?? data['data'] ?? []) as List;
    return list
        .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Vehicle> get(String id) async {
    final resp = await _dio.get('/vehicles/$id');
    return Vehicle.fromJson(_unwrap(resp.data));
  }

  Future<Vehicle> create(Map<String, dynamic> payload) async {
    final resp = await _dio.post('/vehicles', data: payload);
    return Vehicle.fromJson(_unwrap(resp.data));
  }

  Future<Vehicle> update(String id, Map<String, dynamic> payload) async {
    final resp = await _dio.put('/vehicles/$id', data: payload);
    return Vehicle.fromJson(_unwrap(resp.data));
  }

  /// Backend wraps single objects as `{"data": {...}}`.
  Map<String, dynamic> _unwrap(dynamic body) {
    final map = body as Map<String, dynamic>;
    final inner = map['data'];
    return (inner is Map<String, dynamic>) ? inner : map;
  }

  Future<void> delete(String id) async {
    await _dio.delete('/vehicles/$id');
  }

  /// Find vehicles by VIN or plate (mechanic looking up a customer car).
  Future<List<Vehicle>> searchByVinOrPlate(String query) async {
    final resp = await _dio.get('/search', queryParameters: {'q': query});
    final body = _unwrap(resp.data);
    final list = (body['vehicles'] ?? []) as List;
    return list
        .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Send texpasport image to backend for OCR parsing via Claude Vision.
  Future<Map<String, dynamic>> scanPassport(String imagePath) async {
    final form = FormData.fromMap({
      'image': await MultipartFile.fromFile(imagePath),
    });
    final resp = await _dio.post('/vehicles/ocr', data: form);
    return (resp.data as Map<String, dynamic>);
  }
}
