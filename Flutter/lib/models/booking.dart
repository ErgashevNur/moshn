import 'master.dart';

import 'shop.dart';
import 'service_type.dart';
import 'user.dart';
import 'vehicle.dart';

/// Ish bosqichi — bron yaratilganda paketdan ko'chiriladi.
class BookingStage {
  final String id;
  final String name;
  final int sortOrder;
  /// pending | in_progress | done
  final String status;
  final DateTime? startedAt;
  final DateTime? completedAt;

  BookingStage({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.status,
    this.startedAt,
    this.completedAt,
  });

  bool get isDone => status == 'done';
  bool get isActive => status == 'in_progress';

  factory BookingStage.fromJson(Map<String, dynamic> j) => BookingStage(
        id: j['id'] as String,
        name: (j['name'] ?? '') as String,
        sortOrder: ((j['sortOrder'] ?? j['sort_order'] ?? 0) as num).toInt(),
        status: (j['status'] ?? 'pending') as String,
        startedAt: _dt(j['startedAt'] ?? j['started_at']),
        completedAt: _dt(j['completedAt'] ?? j['completed_at']),
      );

  static DateTime? _dt(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;
}

/// Usta yuklagan fotohisobot rasmi.
class BookingPhoto {
  final String id;
  final String url;
  final DateTime createdAt;

  BookingPhoto({required this.id, required this.url, required this.createdAt});

  factory BookingPhoto.fromJson(Map<String, dynamic> j) => BookingPhoto(
        id: j['id'] as String,
        url: (j['url'] ?? '') as String,
        createdAt:
            DateTime.tryParse((j['createdAt'] ?? j['created_at'] ?? '') as String)
                    ?.toLocal() ??
                DateTime.now(),
      );
}

class Booking {
  final String id;
  final String customerId;
  final String shopId;
  final String? masterId;
  final String vehicleId;
  final String serviceTypeId;
  final DateTime scheduledAt;
  final String notes;
  final String status;
  final int totalPrice;
  final String? cancelReason;
  final DateTime? completedAt;
  final DateTime createdAt;

  /// Mijozga ko'rsatiladigan qisqa buyurtma raqami.
  final int orderNo;
  final List<BookingStage> stages;
  final List<BookingPhoto> photos;

  final User? customer;
  final Shop? shop;
  final Master? master;
  final Vehicle? vehicle;
  final ServiceType? serviceType;

  Booking({
    required this.id,
    required this.customerId,
    required this.shopId,
    this.masterId,
    required this.vehicleId,
    required this.serviceTypeId,
    required this.scheduledAt,
    required this.notes,
    required this.status,
    required this.totalPrice,
    this.cancelReason,
    this.completedAt,
    required this.createdAt,
    this.orderNo = 0,
    this.stages = const [],
    this.photos = const [],
    this.customer,
    this.shop,
    this.master,
    this.vehicle,
    this.serviceType,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as String,
        customerId: (json['customerId'] ?? json['customer_id'] ?? '') as String,
        shopId: (json['shopId'] ?? json['shop_id'] ?? '') as String,
        masterId: (json['masterId'] ?? json['master_id']) as String?,
        vehicleId: (json['vehicleId'] ?? json['vehicle_id'] ?? '') as String,
        serviceTypeId: (json['serviceTypeId'] ?? json['service_type_id'] ?? '') as String,
        scheduledAt: DateTime.tryParse(
                (json['scheduledAt'] ?? json['scheduled_at'] ?? '') as String) ??
            DateTime.now(),
        notes: (json['notes'] ?? '') as String,
        status: (json['status'] ?? 'pending') as String,
        totalPrice: ((json['totalPrice'] ?? json['total_price'] ?? 0) as num).toInt(),
        cancelReason: (json['cancelReason'] ?? json['cancel_reason']) as String?,
        completedAt: (json['completedAt'] ?? json['completed_at']) != null
            ? DateTime.tryParse((json['completedAt'] ?? json['completed_at']) as String)
            : null,
        createdAt: DateTime.tryParse(
                (json['createdAt'] ?? json['created_at'] ?? '') as String) ??
            DateTime.now(),
        orderNo: ((json['orderNo'] ?? json['order_no'] ?? 0) as num).toInt(),
        stages: (json['stages'] as List<dynamic>?)
                ?.map((e) => BookingStage.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        photos: (json['photos'] as List<dynamic>?)
                ?.map((e) => BookingPhoto.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        customer: json['customer'] != null
            ? User.fromJson(json['customer'] as Map<String, dynamic>)
            : null,
        shop: json['shop'] != null
            ? Shop.fromJson(json['shop'] as Map<String, dynamic>)
            : null,
        master: json['master'] != null
            ? Master.fromJson(json['master'] as Map<String, dynamic>)
            : null,
        vehicle: json['vehicle'] != null
            ? Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>)
            : null,
        serviceType: (json['serviceType'] ?? json['service_type']) != null
            ? ServiceType.fromJson(
                (json['serviceType'] ?? json['service_type']) as Map<String, dynamic>)
            : null,
      );

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get canCancel => isPending || isConfirmed;

  /// Nechta bosqich yakunlangan.
  int get doneStages => stages.where((s) => s.isDone).length;

  /// Hozir bajarilayotgan bosqich (bo'lsa).
  BookingStage? get activeStage {
    for (final s in stages) {
      if (s.isActive) return s;
    }
    return null;
  }

  /// 0.0–1.0. Bajarilayotgan bosqich yarim hisoblanadi — progress
  /// bosqich boshlanishi bilan siljisin.
  double get progress {
    if (stages.isEmpty) return 0;
    final active = activeStage != null ? 0.5 : 0.0;
    return ((doneStages + active) / stages.length).clamp(0.0, 1.0);
  }
}
