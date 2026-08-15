import 'package:dio/dio.dart';
import '../models/master.dart';
import '../models/review.dart';
import '../models/service_package.dart';
import '../models/shop.dart';
import '../models/service_type.dart';
import 'api.dart';

class SearchResult {
  final List<Shop> shops;
  final List<Master> masters;
  const SearchResult({this.shops = const [], this.masters = const []});
  bool get isEmpty => shops.isEmpty && masters.isEmpty;
}

class ShopService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<ServiceType>> getServiceTypes() async {
    final resp = await _dio.get('/service-types');
    final data = (resp.data['data'] ?? resp.data) as List<dynamic>;
    return data.map((e) => ServiceType.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Bosh ekran qidiruv paneli — ism bo'yicha servis + usta aralash natija.
  Future<SearchResult> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const SearchResult();
    final resp = await _dio.get('/search', queryParameters: {'q': q});
    final payload = (resp.data['data'] ?? resp.data) as Map<String, dynamic>;
    return SearchResult(
      shops: ((payload['shops'] ?? []) as List<dynamic>)
          .map((e) => Shop.fromJson(e as Map<String, dynamic>))
          .toList(),
      masters: ((payload['masters'] ?? []) as List<dynamic>)
          .map((e) => Master.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<List<Shop>> getShops({
    String? serviceType,
    double? lat,
    double? lng,
    /// Berilsa, javobga eng arzon paket narxi va eng yaqin bo'sh vaqt qo'shiladi.
    String? serviceTypeId,
    /// 'rating' | 'price' | 'distance'
    String? sort,
  }) async {
    final params = <String, dynamic>{'limit': 50};
    if (serviceType != null) params['service_type'] = serviceType;
    if (serviceTypeId != null) params['service_type_id'] = serviceTypeId;
    if (sort != null) params['sort'] = sort;
    if (lat != null) params['lat'] = lat;
    if (lng != null) params['lng'] = lng;

    final resp = await _dio.get('/shops', queryParameters: params);
    final payload = (resp.data['data'] ?? resp.data) as Map<String, dynamic>;
    final list = (payload['shops'] ?? []) as List<dynamic>;
    return list.map((e) => Shop.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Shop> getShop(String id) async {
    final resp = await _dio.get('/shops/$id');
    return Shop.fromJson((resp.data['data'] ?? resp.data) as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getMyShop() async {
    final resp = await _dio.get('/service/profile');
    return (resp.data['data'] ?? resp.data) as Map<String, dynamic>;
  }

  Future<void> createProfile(Map<String, dynamic> data) async {
    await _dio.post('/service/profile', data: data);
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    await _dio.put('/service/profile', data: data);
  }

  Future<List<Map<String, dynamic>>> getMyPrices() async {
    final resp = await _dio.get('/service/prices');
    final data = resp.data['data'] as List<dynamic>? ?? [];
    return data.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<void> updatePrices(
      List<Map<String, dynamic>> prices) async {
    await _dio.put('/service/prices', data: {'prices': prices});
  }

  Future<List<Map<String, dynamic>>> getCustomers() async {
    final resp = await _dio.get('/service/customers');
    final payload = (resp.data['data'] ?? resp.data) as Map<String, dynamic>;
    final list = (payload['customers'] ?? []) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> getCustomerCard(String customerId) async {
    final resp = await _dio.get('/service/customers/$customerId');
    return (resp.data['data'] ?? resp.data) as Map<String, dynamic>;
  }

  Future<void> updateCustomerCard(String customerId, Map<String, dynamic> data) async {
    await _dio.put('/service/customers/$customerId', data: data);
  }

  Future<void> setVip(String customerId, bool isVip) async {
    await _dio.put('/service/customers/$customerId', data: {'is_vip': isVip});
  }

  Future<List<DateTime>> getBookedSlots(String shopId, DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final resp = await _dio.get('/shops/$shopId/booked-slots', queryParameters: {
      'date_from': dayStart.toUtc().toIso8601String(),
      'date_to': dayEnd.toUtc().toIso8601String(),
    });
    final data = (resp.data['data'] ?? resp.data) as List<dynamic>;
    return data.map((e) => DateTime.parse(e as String).toLocal()).toList();
  }

  /// Servisning tanlangan xizmat bo'yicha paketlari.
  Future<List<ServicePackage>> getPackages(String shopId, String serviceTypeId) async {
    final resp = await _dio.get('/shops/$shopId/packages',
        queryParameters: {'service_type_id': serviceTypeId});
    final data = (resp.data['data'] ?? resp.data) as List<dynamic>;
    return data
        .map((e) => ServicePackage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Berilgan kundagi bo'sh vaqtlar. Server ish vaqti, ustalar soni va
  /// mavjud bronlarni hisobga oladi.
  Future<List<DateTime>> getAvailability(
    String shopId,
    DateTime date,
    int durationMin,
  ) async {
    final d =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final resp = await _dio.get('/shops/$shopId/availability',
        queryParameters: {'date': d, 'duration': durationMin});
    final data = (resp.data['data'] ?? resp.data) as List<dynamic>;
    return data.map((e) => DateTime.parse(e as String).toLocal()).toList();
  }

  // ── Paketlar (servis egasi) ────────────────────────────────────────────────

  /// Egasining barcha paketlari — nofaollari ham.
  Future<List<ServicePackage>> getMyPackages({String? serviceTypeId}) async {
    final resp = await _dio.get('/service/packages',
        queryParameters: {'service_type_id': ?serviceTypeId});
    final data = (resp.data['data'] ?? resp.data) as List<dynamic>;
    return data
        .map((e) => ServicePackage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ServicePackage> createPackage({
    required String serviceTypeId,
    required String name,
    String description = '',
    int durationMin = 60,
    int price = 0,
    int sortOrder = 0,
  }) async {
    final resp = await _dio.post('/service/packages', data: {
      'service_type_id': serviceTypeId,
      'name': name,
      'description': description,
      'duration_min': durationMin,
      'price': price,
      'sort_order': sortOrder,
    });
    return ServicePackage.fromJson((resp.data['data'] ?? resp.data) as Map<String, dynamic>);
  }

  Future<ServicePackage> updatePackage(
    String id, {
    String? name,
    String? description,
    int? durationMin,
    int? price,
    bool? isActive,
  }) async {
    final resp = await _dio.put('/service/packages/$id', data: {
      'name': ?name,
      'description': ?description,
      'duration_min': ?durationMin,
      'price': ?price,
      'is_active': ?isActive,
    });
    return ServicePackage.fromJson((resp.data['data'] ?? resp.data) as Map<String, dynamic>);
  }

  Future<void> deletePackage(String id) async {
    await _dio.delete('/service/packages/$id');
  }

  Future<List<Review>> getShopReviews(String shopId, {int page = 1, int limit = 10}) async {
    final resp = await _dio.get(
      '/shops/$shopId/reviews',
      queryParameters: {'page': page, 'limit': limit},
    );
    final payload = (resp.data['data'] ?? resp.data) as Map<String, dynamic>;
    final list = (payload['reviews'] ?? []) as List<dynamic>;
    return list.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
  }
}
