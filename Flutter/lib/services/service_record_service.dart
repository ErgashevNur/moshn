import 'package:dio/dio.dart';
import '../models/service_record.dart';
import 'api.dart';

class ServiceRecordService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<ServiceRecord>> listForVehicle(String vehicleId) async {
    final resp = await _dio.get('/vehicles/$vehicleId/history');
    return _parseList(resp.data, ['services', 'history', 'records']);
  }

  Future<List<ServiceRecord>> pendingForOwner() async {
    final resp = await _dio.get('/services/pending');
    return _parseList(resp.data, ['services', 'records']);
  }

  /// Service records created by the signed-in mechanic.
  Future<List<ServiceRecord>> myServices() async {
    final resp = await _dio.get('/mechanics/my-services');
    return _parseList(resp.data, ['records', 'services']);
  }

  /// Backend wraps lists as `{"data": {"<key>": [...]}}` or `{"data": [...]}`.
  List<ServiceRecord> _parseList(dynamic body, List<String> keys) {
    final inner = _unwrap(body);
    dynamic raw;
    if (body is Map && body['data'] is List) {
      raw = body['data'];
    } else {
      for (final k in keys) {
        if (inner[k] is List) {
          raw = inner[k];
          break;
        }
      }
    }
    final list = (raw ?? []) as List;
    return list
        .map((e) => ServiceRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ServiceRecord> get(String id) async {
    final resp = await _dio.get('/services/$id');
    return ServiceRecord.fromJson(_unwrap(resp.data));
  }

  Future<ServiceRecord> create(Map<String, dynamic> payload) async {
    final resp = await _dio.post('/services', data: payload);
    return ServiceRecord.fromJson(_unwrap(resp.data));
  }

  Map<String, dynamic> _unwrap(dynamic body) {
    final map = body as Map<String, dynamic>;
    final inner = map['data'];
    return (inner is Map<String, dynamic>) ? inner : map;
  }

  Future<void> confirm(String id) async {
    await _dio.put('/services/$id/confirm');
  }

  Future<void> reject(String id, {String? reason}) async {
    await _dio.put('/services/$id/reject', data: {'reason': reason});
  }

  /// Upload voice file → backend returns parsed JSON (UzbekVoice + Claude).
  Future<Map<String, dynamic>> parseVoice(String audioPath) async {
    final form = FormData.fromMap({
      'audio': await MultipartFile.fromFile(audioPath),
    });
    final resp = await _dio.post('/services/voice', data: form);
    return (resp.data as Map<String, dynamic>);
  }
}
