import 'package:dio/dio.dart';
import '../models/sos_request.dart';
import 'api.dart';

/// SOS — favqulodda yordam so'rovi backendga yuboriladi.
class SosService {
  final Dio _dio = ApiClient.instance.dio;

  Future<void> send({
    required String phone,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    await _dio.post('/sos', data: {
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
      if (address != null && address.isNotEmpty) 'address': address,
    });
  }

  /// Mijozning o'z SOS so'rovlari (eng yangisi birinchi).
  Future<List<SosRequest>> mine() async {
    final resp = await _dio.get('/sos');
    final body = resp.data as Map<String, dynamic>;
    final inner = (body['data'] is Map<String, dynamic>)
        ? body['data'] as Map<String, dynamic>
        : body;
    final list = (inner['requests'] ?? inner['data'] ?? []) as List;
    return list
        .map((e) => SosRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
