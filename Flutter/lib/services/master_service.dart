import 'package:dio/dio.dart';
import '../models/master.dart';
import '../models/review.dart';
import 'api.dart';

class MasterService {
  final Dio _dio = ApiClient.instance.dio;

  /// Servisning faol ustalari (mijoz uchun — yozilishda tanlash).
  Future<List<Master>> getShopMasters(String shopId) async {
    final resp = await _dio.get('/shops/$shopId/masters');
    final payload = (resp.data['data'] ?? resp.data) as Map<String, dynamic>;
    final list = (payload['masters'] ?? []) as List<dynamic>;
    return list.map((e) => Master.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Usta kartochkasi (ommaviy).
  Future<Master> getMaster(String id) async {
    final resp = await _dio.get('/masters/$id');
    return Master.fromJson((resp.data['data'] ?? resp.data) as Map<String, dynamic>);
  }

  /// Ustaning berilgan kundagi band vaqtlari (bron kalendari uchun).
  Future<List<DateTime>> getBookedSlots(String masterId, DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final resp = await _dio.get('/masters/$masterId/booked-slots', queryParameters: {
      'date_from': dayStart.toUtc().toIso8601String(),
      'date_to': dayEnd.toUtc().toIso8601String(),
    });
    final data = (resp.data['data'] ?? resp.data) as List<dynamic>;
    return data.map((e) => DateTime.parse(e as String).toLocal()).toList();
  }

  // ── Servis egasi tomonidan boshqaruv ───────────────────────────────────────

  Future<List<Master>> listMyMasters() async {
    final resp = await _dio.get('/service/masters');
    final payload = (resp.data['data'] ?? resp.data) as Map<String, dynamic>;
    final list = (payload['masters'] ?? []) as List<dynamic>;
    return list.map((e) => Master.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Master> createMaster({
    required String phone,
    required String email,
    required String password,
    required String fullName,
    String position = '',
    List<String> serviceTypeIds = const [],
  }) async {
    final resp = await _dio.post('/service/masters', data: {
      'phone': phone,
      'email': email,
      'password': password,
      'full_name': fullName,
      'position': position,
      'service_type_ids': serviceTypeIds,
    });
    return Master.fromJson((resp.data['data'] ?? resp.data) as Map<String, dynamic>);
  }

  Future<Master> updateMaster(
    String id, {
    String? fullName,
    String? position,
    bool? isActive,
    List<String>? serviceTypeIds,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['full_name'] = fullName;
    if (position != null) body['position'] = position;
    if (isActive != null) body['is_active'] = isActive;
    if (serviceTypeIds != null) body['service_type_ids'] = serviceTypeIds;
    final resp = await _dio.put('/service/masters/$id', data: body);
    return Master.fromJson((resp.data['data'] ?? resp.data) as Map<String, dynamic>);
  }

  Future<void> deactivateMaster(String id) async {
    await _dio.delete('/service/masters/$id');
  }

  Future<List<Review>> getMasterReviews(String masterId, {int page = 1, int limit = 10}) async {
    final resp = await _dio.get(
      '/masters/$masterId/reviews',
      queryParameters: {'page': page, 'limit': limit},
    );
    final payload = (resp.data['data'] ?? resp.data) as Map<String, dynamic>;
    final list = (payload['reviews'] ?? []) as List<dynamic>;
    return list.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
  }
}
