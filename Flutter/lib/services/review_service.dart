import 'package:dio/dio.dart';
import '../models/review.dart';
import 'api.dart';

class ReviewService {
  final Dio _dio = ApiClient.instance.dio;

  // owner_to_shop yoki shop_to_owner
  Future<Review> createReview({
    required String bookingId,
    required String targetId,
    required String reviewType,
    required int rating,
    String comment = '',
  }) async {
    final resp = await _dio.post('/reviews', data: {
      'booking_id':   bookingId,
      'target_id':    targetId,
      'review_type':  reviewType,
      'rating':       rating,
      'comment':      comment,
    });
    return Review.fromJson((resp.data['data'] ?? resp.data) as Map<String, dynamic>);
  }

  Future<List<Review>> getCustomerReviews(String customerId) async {
    final resp = await _dio.get('/reviews/customer/$customerId');
    final payload = (resp.data['data'] ?? resp.data) as Map<String, dynamic>;
    final list = (payload['reviews'] ?? []) as List<dynamic>;
    return list.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
  }
}
