import 'package:dio/dio.dart';
import '../models/sos_request.dart';
import 'api.dart';

class SosService {
  final Dio _dio = ApiClient.instance.dio;

  // ── Mijoz ────────────────────────────────────────────────────────────────

  Future<SosRequest> create({
    required String vehicleId,
    required String serviceTypeId,
    required double lat,
    required double lng,
  }) async {
    final resp = await _dio.post('/sos', data: {
      'vehicle_id': vehicleId,
      'service_type_id': serviceTypeId,
      'lat': lat,
      'lng': lng,
    });
    return SosRequest.fromJson((resp.data['data'] ?? resp.data) as Map<String, dynamic>);
  }

  Future<SosRequest> getStatus(String id) async {
    final resp = await _dio.get('/sos/$id');
    return SosRequest.fromJson((resp.data['data'] ?? resp.data) as Map<String, dynamic>);
  }

  Future<SosRequest> cancel(String id) async {
    final resp = await _dio.post('/sos/$id/cancel');
    return SosRequest.fromJson((resp.data['data'] ?? resp.data) as Map<String, dynamic>);
  }

  Future<void> requestSupport(String id) async {
    await _dio.post('/sos/$id/support');
  }

  /// Hech kim topilmagandan keyin ("no_master_found") evakuator chaqirish.
  Future<SosRequest> requestEvacuator(String id) async {
    final resp = await _dio.post('/sos/$id/request-evacuator');
    return SosRequest.fromJson((resp.data['data'] ?? resp.data) as Map<String, dynamic>);
  }

  // ── Chat (mijoz ↔ qabul qilgan usta) ────────────────────────────────────────

  Future<SosMessage> sendMessage(String id, String body) async {
    final resp = await _dio.post('/sos/$id/messages', data: {'body': body});
    return SosMessage.fromJson((resp.data['data'] ?? resp.data) as Map<String, dynamic>);
  }

  Future<List<SosMessage>> getMessages(String id) async {
    final resp = await _dio.get('/sos/$id/messages');
    final list = (resp.data['data'] ?? resp.data) as List<dynamic>;
    return list.map((e) => SosMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Usta ─────────────────────────────────────────────────────────────────

  Future<List<SosIncomingRequest>> listForMaster() async {
    final resp = await _dio.get('/master/sos-requests');
    final list = (resp.data['data'] ?? resp.data) as List<dynamic>;
    return list.map((e) => SosIncomingRequest.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Usta hozir bajarayotgan (qabul qilingan) ish, bo'lmasa — null.
  Future<SosRequest?> getActiveForMaster() async {
    final resp = await _dio.get('/master/sos-requests/active');
    final data = resp.data['data'] ?? resp.data;
    if (data == null) return null;
    return SosRequest.fromJson(data as Map<String, dynamic>);
  }

  Future<SosRequest> accept(String sosRequestId) async {
    final resp = await _dio.post('/master/sos-requests/$sosRequestId/accept');
    return SosRequest.fromJson((resp.data['data'] ?? resp.data) as Map<String, dynamic>);
  }

  Future<SosRequest> updateStatus(String id, String status) async {
    final resp = await _dio.post('/sos/$id/status', data: {'status': status});
    return SosRequest.fromJson((resp.data['data'] ?? resp.data) as Map<String, dynamic>);
  }

  // ── Evakuator ────────────────────────────────────────────────────────────

  Future<List<SosIncomingRequest>> listForEvacuator() async {
    final resp = await _dio.get('/evacuator/sos-requests');
    final list = (resp.data['data'] ?? resp.data) as List<dynamic>;
    return list.map((e) => SosIncomingRequest.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Evakuator hozir bajarayotgan (qabul qilingan) ish, bo'lmasa — null.
  Future<SosRequest?> getActiveForEvacuator() async {
    final resp = await _dio.get('/evacuator/sos-requests/active');
    final data = resp.data['data'] ?? resp.data;
    if (data == null) return null;
    return SosRequest.fromJson(data as Map<String, dynamic>);
  }

  Future<SosRequest> acceptAsEvacuator(String sosRequestId) async {
    final resp = await _dio.post('/evacuator/sos-requests/$sosRequestId/accept');
    return SosRequest.fromJson((resp.data['data'] ?? resp.data) as Map<String, dynamic>);
  }

  // ── To'lov (Faza 3.8) ────────────────────────────────────────────────────

  /// Qabul qilgan tomon (usta/evakuator) yakuniy narxni kiritadi — faqat
  /// xizmat "completed" bo'lgandan keyin, faqat bir marta.
  Future<SosRequest> setPrice(String id, int amount) async {
    final resp = await _dio.post('/sos/$id/price', data: {'amount': amount});
    return SosRequest.fromJson((resp.data['data'] ?? resp.data) as Map<String, dynamic>);
  }

  /// Mijoz to'lovni tasdiqlaydi (real gateway hali yo'q — MVP qo'lda tasdiqlash).
  Future<SosRequest> confirmPayment(String id, {String method = 'card_qr'}) async {
    final resp = await _dio.post('/sos/$id/payment/confirm', data: {'method': method});
    return SosRequest.fromJson((resp.data['data'] ?? resp.data) as Map<String, dynamic>);
  }

  Future<void> addTip(String id, int amount) async {
    await _dio.post('/sos/$id/tip', data: {'amount': amount});
  }
}

/// [DioException]dan foydalanuvchiga ko'rsatiladigan xabarni chiqaradi —
/// create_booking_screen'dagi xatolik-ko'rsatish andozasi bilan bir xil.
String sosErrorMessage(Object e, {String fallback = 'Xatolik yuz berdi'}) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map) {
      return (data['message'] ?? data['error'] ?? fallback).toString();
    }
    if (e.response?.statusCode != null) {
      return 'Server xatosi (${e.response?.statusCode})';
    }
    return 'Tarmoq xatosi. Internetni tekshiring';
  }
  return fallback;
}
