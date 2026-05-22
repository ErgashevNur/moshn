import 'package:dio/dio.dart';
import '../models/assignment.dart';
import 'api.dart';

/// Tamirlash so'rovlari: mijoz usta tanlab so'rov yuboradi; usta o'ziga
/// yo'naltirilgan SOS va tamirlash so'rovlarini mijoz ma'lumotlari bilan ko'radi.
class RepairService {
  final Dio _dio = ApiClient.instance.dio;

  /// Mijoz tamirlash so'rovini yuboradi (ixtiyoriy usta tanlab).
  Future<void> createRequest({
    String? preferredMechanicId,
    required String phone,
    String? carInfo,
    required String description,
  }) async {
    await _dio.post('/repair-requests', data: {
      'preferred_mechanic_id': ?preferredMechanicId,
      'phone': phone,
      if (carInfo != null && carInfo.isNotEmpty) 'car_info': carInfo,
      'description': description,
    });
  }

  /// Ustaga yo'naltirilgan SOS + tamirlash so'rovlari (mijoz ma'lumotlari bilan).
  Future<List<Assignment>> myAssignments() async {
    final resp = await _dio.get('/mechanic/assignments');
    final inner = _unwrap(resp.data);
    final sos = (inner['sos'] as List?) ?? [];
    final repairs = (inner['repairs'] as List?) ?? [];
    final items = <Assignment>[
      ...sos.map((e) => Assignment.sos(e as Map<String, dynamic>)),
      ...repairs.map((e) => Assignment.repair(e as Map<String, dynamic>)),
    ];
    items.sort((a, b) =>
        (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return items;
  }

  Map<String, dynamic> _unwrap(dynamic body) {
    final map = body as Map<String, dynamic>;
    final inner = map['data'];
    return (inner is Map<String, dynamic>) ? inner : map;
  }
}
