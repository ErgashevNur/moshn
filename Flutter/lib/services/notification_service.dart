import 'package:dio/dio.dart';
import '../models/notification.dart';
import 'api.dart';

class NotificationService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<AppNotification>> list() async {
    final resp = await _dio.get('/notifications');
    // Backend javobi: {"data": {"notifications": [...], "total": N}}
    final body = resp.data as Map<String, dynamic>;
    final inner = (body['data'] is Map<String, dynamic>)
        ? body['data'] as Map<String, dynamic>
        : body;
    final list = (inner['notifications'] ?? inner['data'] ?? []) as List;
    return list
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markRead(String id) async {
    await _dio.put('/notifications/$id/read');
  }

  Future<void> registerToken(String fcmToken, {String platform = 'android'}) async {
    await _dio.post('/notifications/fcm-token', data: {
      'token': fcmToken,
      'platform': platform,
    });
  }
}
