import 'package:dio/dio.dart';
import '../models/shop.dart';
import '../models/service_type.dart';
import 'api.dart';

class ShopService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<ServiceType>> getServiceTypes() async {
    final resp = await _dio.get('/service-types');
    final data = (resp.data['data'] ?? resp.data) as List<dynamic>;
    return data.map((e) => ServiceType.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Shop>> getShops({String? serviceType, double? lat, double? lng}) async {
    final params = <String, dynamic>{'limit': 50};
    if (serviceType != null) params['service_type'] = serviceType;
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

  Future<void> updateProfile(Map<String, dynamic> data) async {
    await _dio.put('/service/profile', data: data);
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
    await _dio.put('/service/customers/$customerId/vip', data: {'is_vip': isVip});
  }
}
