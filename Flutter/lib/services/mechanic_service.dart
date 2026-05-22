import 'package:dio/dio.dart';
import '../models/mechanic.dart';
import '../models/review.dart';
import 'api.dart';

class MechanicService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<Mechanic>> search({String? q, String? specialization}) async {
    final resp = await _dio.get('/mechanics', queryParameters: {
      'q': ?q,
      'specialization': ?specialization,
    });
    final inner = _unwrap(resp.data);
    final list = (inner['mechanics'] ?? inner['data'] ?? []) as List;
    return list.map((e) => Mechanic.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Mechanic> get(String id) async {
    final resp = await _dio.get('/mechanics/$id');
    final inner = _unwrap(resp.data);
    // Single mechanic may sit at the root or under a `mechanic` key.
    final m = (inner['mechanic'] as Map<String, dynamic>?) ?? inner;
    return Mechanic.fromJson(m);
  }

  /// Usta haqidagi sharhlar: GET /mechanics/:id/reviews
  Future<List<Review>> reviews(String id) async {
    final resp = await _dio.get('/mechanics/$id/reviews');
    final inner = _unwrap(resp.data);
    final list = (inner['reviews'] ?? inner['data'] ?? []) as List;
    return list.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Backend wraps responses as `{"data": ...}`.
  Map<String, dynamic> _unwrap(dynamic body) {
    final map = body as Map<String, dynamic>;
    final inner = map['data'];
    return (inner is Map<String, dynamic>) ? inner : map;
  }

  /// Backend uses /mechanics/:id; mechanic's own id comes from /profile.
  Future<Mechanic> getById(String id) => get(id);
}
