import 'package:dio/dio.dart';
import '../models/promo.dart';
import 'api.dart';

class PromoService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<Promo>> getActive() async {
    final resp = await _dio.get('/promos/active');
    final data = (resp.data['data'] ?? resp.data) as List<dynamic>;
    return data.map((e) => Promo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> trackView(String id) async {
    try {
      await _dio.post('/promos/$id/view');
    } catch (_) {
      // аналитика — пусть молчит, не должна влиять на UI
    }
  }

  Future<void> trackClick(String id) async {
    try {
      await _dio.post('/promos/$id/click');
    } catch (_) {
      // аналитика — пусть молчит, не должна влиять на UI
    }
  }
}
