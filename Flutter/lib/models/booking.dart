import 'master.dart';

import 'service_package.dart';
import 'shop.dart';
import 'service_type.dart';
import 'user.dart';
import 'vehicle.dart';

/// Ish bosqichi — bron yaratilganda paketdan ko'chiriladi.
class BookingStage {
  final String id;
  final String name;
  final int sortOrder;
  /// pending | in_progress | awaiting_customer | done
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

  /// Usta qo'shimcha ish taklif qildi — mijozning javobi kutilmoqda.
  bool get isAwaiting => status == 'awaiting_customer';

  /// Javob uzoq kutilib qolgan bo'lsa maketdagi "Просрочено" yozuvi
  /// chiqadi — mijoz taklifni ko'rmay o'tkazib yubormasin.
  static const overdueAfter = Duration(minutes: 15);

  bool get isOverdue =>
      isAwaiting &&
      startedAt != null &&
      DateTime.now().difference(startedAt!) > overdueAfter;

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

/// Ish davomida usta taklif qilgan qo'shimcha ish. Narx faqat mijoz
/// tasdiqlagandan keyin hisobga qo'shiladi.
class BookingExtra {
  final String id;
  final String? stageId;
  final String name;
  final int price;

  /// proposed | approved | rejected
  final String status;
  final DateTime? respondedAt;
  final DateTime createdAt;

  BookingExtra({
    required this.id,
    this.stageId,
    required this.name,
    required this.price,
    required this.status,
    this.respondedAt,
    required this.createdAt,
  });

  bool get isProposed => status == 'proposed';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory BookingExtra.fromJson(Map<String, dynamic> j) => BookingExtra(
        id: j['id'] as String,
        stageId: (j['stageId'] ?? j['stage_id']) as String?,
        name: (j['name'] ?? '') as String,
        price: ((j['price'] ?? 0) as num).toInt(),
        status: (j['status'] ?? 'proposed') as String,
        respondedAt: BookingStage._dt(j['respondedAt'] ?? j['responded_at']),
        createdAt: BookingStage._dt(j['createdAt'] ?? j['created_at']) ??
            DateTime.now(),
      );
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
  final List<BookingExtra> extras;
  final List<BookingPhoto> photos;

  /// Mijoz tanlagan paket (bo'lsa) — "К оплате" dagi asosiy qator.
  final ServicePackage? package;

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
    this.extras = const [],
    this.photos = const [],
    this.package,
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
        extras: (json['extras'] as List<dynamic>?)
                ?.map((e) => BookingExtra.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        photos: (json['photos'] as List<dynamic>?)
                ?.map((e) => BookingPhoto.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        package: json['package'] != null
            ? ServicePackage.fromJson(json['package'] as Map<String, dynamic>)
            : null,
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

  /// Mijozning javobi kutilayotgan taklif (bo'lsa).
  BookingStage? get awaitingStage {
    for (final s in stages) {
      if (s.isAwaiting) return s;
    }
    return null;
  }

  /// Javob berilmagan takliflar — mijozga "Rozi / Rad et" tugmalari
  /// shular uchun ko'rsatiladi.
  List<BookingExtra> get proposedExtras =>
      extras.where((e) => e.isProposed).toList();

  /// Tasdiqlangan takliflar — "К оплате" ga alohida qator bo'lib tushadi.
  List<BookingExtra> get approvedExtras =>
      extras.where((e) => e.isApproved).toList();

  /// Paket narxi. `totalPrice` ga tasdiqlangan takliflar allaqachon
  /// qo'shilgan (server tomonda), shuning uchun ayirib olinadi — shunda
  /// qatorlar yig'indisi doim "Итого" ga teng chiqadi, paket narxi keyin
  /// o'zgargan bo'lsa ham.
  int get basePrice {
    final extrasSum =
        approvedExtras.fold<int>(0, (sum, e) => sum + e.price);
    final base = totalPrice - extrasSum;
    return base < 0 ? 0 : base;
  }

  /// Nechanchi qadamdamiz ("3 из 5" belgisidagi 3). Bajarilayotgan bosqich
  /// ham sanaladi — chiziq bosqich boshlanishi bilan siljisin.
  int get currentStep => doneStages + (activeStage != null ? 1 : 0);

  /// 0.0–1.0. `currentStep / jami` — shunda maketdagidek "3 из 5" va "60%"
  /// bir xil narsani aytadi (avval foiz yarim qadamga orqada qolardi).
  double get progress {
    if (stages.isEmpty) return 0;
    return (currentStep / stages.length).clamp(0.0, 1.0);
  }
}
