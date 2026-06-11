import 'shop.dart';
import 'service_type.dart';
import 'user.dart';
import 'vehicle.dart';

class Booking {
  final String id;
  final String customerId;
  final String shopId;
  final String vehicleId;
  final String serviceTypeId;
  final DateTime scheduledAt;
  final String notes;
  final String status;
  final int totalPrice;
  final String? cancelReason;
  final DateTime? completedAt;
  final DateTime createdAt;

  final User? customer;
  final Shop? shop;
  final Vehicle? vehicle;
  final ServiceType? serviceType;

  Booking({
    required this.id,
    required this.customerId,
    required this.shopId,
    required this.vehicleId,
    required this.serviceTypeId,
    required this.scheduledAt,
    required this.notes,
    required this.status,
    required this.totalPrice,
    this.cancelReason,
    this.completedAt,
    required this.createdAt,
    this.customer,
    this.shop,
    this.vehicle,
    this.serviceType,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as String,
        customerId: (json['customer_id'] ?? '') as String,
        shopId: (json['shop_id'] ?? '') as String,
        vehicleId: (json['vehicle_id'] ?? '') as String,
        serviceTypeId: (json['service_type_id'] ?? '') as String,
        scheduledAt:
            DateTime.tryParse(json['scheduled_at'] ?? '') ?? DateTime.now(),
        notes: (json['notes'] ?? '') as String,
        status: (json['status'] ?? 'pending') as String,
        totalPrice: (json['total_price'] ?? 0) as int,
        cancelReason: json['cancel_reason'] as String?,
        completedAt: json['completed_at'] != null
            ? DateTime.tryParse(json['completed_at'] as String)
            : null,
        createdAt:
            DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
        customer: json['customer'] != null
            ? User.fromJson(json['customer'] as Map<String, dynamic>)
            : null,
        shop: json['shop'] != null
            ? Shop.fromJson(json['shop'] as Map<String, dynamic>)
            : null,
        vehicle: json['vehicle'] != null
            ? Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>)
            : null,
        serviceType: json['service_type'] != null
            ? ServiceType.fromJson(json['service_type'] as Map<String, dynamic>)
            : null,
      );

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get canCancel => isPending || isConfirmed;
}
