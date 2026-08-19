import 'package:dio/dio.dart';
import '../models/booking.dart';
import '../models/payment.dart';
import 'api.dart';

class BookingService {
  final Dio _dio = ApiClient.instance.dio;

  Future<Booking> createBooking({
    required String shopId,
    /// Bo'sh qoldirilsa server o'zi shu vaqtda bo'sh ustani tayinlaydi.
    String? masterId,
    String? packageId,
    required String vehicleId,
    required String serviceTypeId,
    required DateTime scheduledAt,
    String notes = '',
    int totalPrice = 0,
  }) async {
    final resp = await _dio.post('/bookings', data: {
      'shop_id': shopId,
      'master_id': ?masterId,
      'package_id': ?packageId,
      'vehicle_id': vehicleId,
      'service_type_id': serviceTypeId,
      'scheduled_at': scheduledAt.toUtc().toIso8601String(),
      'notes': notes,
      'total_price': totalPrice,
    });
    return Booking.fromJson((resp.data['data'] ?? resp.data) as Map<String, dynamic>);
  }

  Future<List<Booking>> getMyBookings({String? status}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    final resp = await _dio.get('/bookings', queryParameters: params);
    final payload = (resp.data['data'] ?? resp.data) as Map<String, dynamic>;
    final list = (payload['bookings'] ?? []) as List<dynamic>;
    return list.map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Booking> getBooking(String id) async {
    final resp = await _dio.get('/bookings/$id');
    return Booking.fromJson((resp.data['data'] ?? resp.data) as Map<String, dynamic>);
  }

  Future<void> cancelBooking(String id, {String reason = ''}) async {
    await _dio.put('/bookings/$id/cancel', data: {'reason': reason});
  }

  // --- Usta roli uchun ---

  Future<List<Booking>> getMasterBookings({String? status}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    final resp = await _dio.get('/master/bookings', queryParameters: params);
    final payload = (resp.data['data'] ?? resp.data) as Map<String, dynamic>;
    final list = (payload['bookings'] ?? []) as List<dynamic>;
    return list.map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
  }

  // --- Для роли сервиса ---

  Future<List<Booking>> getShopBookings({String? status}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    final resp = await _dio.get('/service/bookings', queryParameters: params);
    final payload = (resp.data['data'] ?? resp.data) as Map<String, dynamic>;
    final list = (payload['bookings'] ?? []) as List<dynamic>;
    return list.map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Booking> confirmBooking(String id) async {
    final resp = await _dio.put('/service/bookings/$id/confirm');
    return Booking.fromJson((resp.data['data'] ?? resp.data) as Map<String, dynamic>);
  }

  Future<Booking> startBooking(String id) async {
    final resp = await _dio.put('/service/bookings/$id/start');
    return Booking.fromJson((resp.data['data'] ?? resp.data) as Map<String, dynamic>);
  }

  Future<Booking> completeBooking(String id) async {
    final resp = await _dio.put('/service/bookings/$id/complete');
    return Booking.fromJson((resp.data['data'] ?? resp.data) as Map<String, dynamic>);
  }

  Future<void> shopCancelBooking(String id, {String reason = ''}) async {
    await _dio.put('/service/bookings/$id/cancel', data: {'reason': reason});
  }

  // --- Ish bosqichlari, fotohisobot, qo'shimcha ish ---

  /// Bosqich holatini belgilaydi (usta yoki servis egasi).
  /// `status`: pending | in_progress | done
  Future<Booking> setStageStatus(
    String bookingId,
    String stageId,
    String status,
  ) async {
    final resp = await _dio.put(
      '/bookings/$bookingId/stages/$stageId',
      data: {'status': status},
    );
    return Booking.fromJson((resp.data['data'] ?? resp.data) as Map<String, dynamic>);
  }

  /// Fotohisobotga rasm qo'shadi.
  Future<Booking> addBookingPhoto(
    String bookingId,
    String filePath, {
    String? stageId,
  }) async {
    final form = FormData.fromMap({
      'photo': await MultipartFile.fromFile(filePath),
      'stage_id': ?stageId,
    });
    final resp = await _dio.post('/bookings/$bookingId/photos', data: form);
    return Booking.fromJson((resp.data['data'] ?? resp.data) as Map<String, dynamic>);
  }

  /// Usta qo'shimcha ish taklif qiladi. Narx mijoz tasdiqlagunga qadar
  /// hisobga qo'shilmaydi.
  Future<Booking> proposeExtra(
    String bookingId, {
    required String name,
    required int price,
  }) async {
    final resp = await _dio.post(
      '/bookings/$bookingId/extras',
      data: {'name': name, 'price': price},
    );
    return Booking.fromJson((resp.data['data'] ?? resp.data) as Map<String, dynamic>);
  }

  /// Mijoz taklifga javob beradi.
  Future<Booking> respondToExtra(
    String bookingId,
    String extraId, {
    required bool approve,
  }) async {
    final resp = await _dio.post(
      '/bookings/$bookingId/extras/$extraId/respond',
      data: {'approve': approve},
    );
    return Booking.fromJson((resp.data['data'] ?? resp.data) as Map<String, dynamic>);
  }

  // --- Оплата ---

  Future<Payment> generateQR(String bookingId) async {
    final resp = await _dio.post('/payments/$bookingId/qr');
    return Payment.fromJson((resp.data['data'] ?? resp.data) as Map<String, dynamic>);
  }

  Future<Payment> markPaid(String bookingId, String method) async {
    final resp = await _dio.post('/payments/$bookingId/pay', data: {'method': method});
    return Payment.fromJson((resp.data['data'] ?? resp.data) as Map<String, dynamic>);
  }

  Future<void> addTip(String bookingId, int amount) async {
    await _dio.post('/payments/$bookingId/tip', data: {'amount': amount});
  }

  Future<Payment?> getPayment(String bookingId) async {
    try {
      final resp = await _dio.get('/payments/$bookingId');
      return Payment.fromJson((resp.data['data'] ?? resp.data) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
