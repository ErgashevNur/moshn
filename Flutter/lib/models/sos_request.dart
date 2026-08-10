import 'service_type.dart';
import 'vehicle.dart';

/// SOS so'roviga bitta servisga (yoki evakuatorga) qaysi to'lqinda
/// yuborilgani va javobi. `shopId`/`evacuatorId`dan faqat bittasi to'ladi.
class SosDispatchInfo {
  final String id;
  final String? shopId;
  final String? evacuatorId;
  final int wave;
  final int distanceMeters;
  final String status; // sent | accepted | taken | expired
  final DateTime sentAt;
  final DateTime? respondedAt;

  SosDispatchInfo({
    required this.id,
    this.shopId,
    this.evacuatorId,
    required this.wave,
    required this.distanceMeters,
    required this.status,
    required this.sentAt,
    this.respondedAt,
  });

  factory SosDispatchInfo.fromJson(Map<String, dynamic> json) => SosDispatchInfo(
        id: json['id'] as String,
        shopId: (json['shopId'] ?? json['shop_id']) as String?,
        evacuatorId: (json['evacuatorId'] ?? json['evacuator_id']) as String?,
        wave: ((json['wave'] ?? 1) as num).toInt(),
        distanceMeters: ((json['distanceMeters'] ?? json['distance_meters'] ?? 0) as num).toInt(),
        status: (json['status'] ?? 'sent') as String,
        sentAt: DateTime.tryParse((json['sentAt'] ?? json['sent_at'] ?? '') as String) ?? DateTime.now(),
        respondedAt: (json['respondedAt'] ?? json['responded_at']) != null
            ? DateTime.tryParse((json['respondedAt'] ?? json['responded_at']) as String)
            : null,
      );
}

/// Qabul qilgan usta va uning servisi (mijozga ko'rsatish uchun).
class SosAcceptedMaster {
  final String id;
  final String fullName;
  final String avatarUrl;
  final double ratingAvg;
  final String shopName;
  final String shopPhone;
  final String shopAddress;

  SosAcceptedMaster({
    required this.id,
    required this.fullName,
    required this.avatarUrl,
    required this.ratingAvg,
    required this.shopName,
    required this.shopPhone,
    required this.shopAddress,
  });

  factory SosAcceptedMaster.fromJson(Map<String, dynamic> json) {
    final shop = json['shop'] as Map<String, dynamic>? ?? {};
    return SosAcceptedMaster(
      id: json['id'] as String,
      fullName: (json['fullName'] ?? json['full_name'] ?? '') as String,
      avatarUrl: (json['avatarUrl'] ?? json['avatar_url'] ?? '') as String,
      ratingAvg: ((json['ratingAvg'] ?? json['rating_avg'] ?? 0.0) as num).toDouble(),
      shopName: (shop['shopName'] ?? shop['shop_name'] ?? '') as String,
      shopPhone: (shop['phone'] ?? '') as String,
      shopAddress: (shop['address'] ?? '') as String,
    );
  }
}

/// Qabul qilgan evakuator (mijozga ko'rsatish uchun, Faza 3.7).
class SosAcceptedEvacuator {
  final String id;
  final String fullName;
  final String phone;
  final String vehiclePlate;
  final double ratingAvg;

  SosAcceptedEvacuator({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.vehiclePlate,
    required this.ratingAvg,
  });

  factory SosAcceptedEvacuator.fromJson(Map<String, dynamic> json) => SosAcceptedEvacuator(
        id: json['id'] as String,
        fullName: (json['fullName'] ?? json['full_name'] ?? '') as String,
        phone: (json['phone'] ?? '') as String,
        vehiclePlate: (json['vehiclePlate'] ?? json['vehicle_plate'] ?? '') as String,
        ratingAvg: ((json['ratingAvg'] ?? json['rating_avg'] ?? 0.0) as num).toDouble(),
      );
}

/// Xizmat yakunlangach kiritilgan narx/to'lov holati (Faza 3.8).
class SosPayment {
  final String id;
  final int amount;
  final String method;
  final String status; // pending | paid
  final String qrCode;
  final DateTime? paidAt;

  SosPayment({
    required this.id,
    required this.amount,
    required this.method,
    required this.status,
    required this.qrCode,
    this.paidAt,
  });

  bool get isPaid => status == 'paid';

  factory SosPayment.fromJson(Map<String, dynamic> json) => SosPayment(
        id: json['id'] as String,
        amount: ((json['amount'] ?? 0) as num).toInt(),
        method: (json['method'] ?? '') as String,
        status: (json['status'] ?? 'pending') as String,
        qrCode: (json['qrCode'] ?? json['qr_code'] ?? '') as String,
        paidAt: (json['paidAt'] ?? json['paid_at']) != null
            ? DateTime.tryParse((json['paidAt'] ?? json['paid_at']) as String)
            : null,
      );
}

class SosRequest {
  final String id;
  final String status;
  final String dispatchMode; // 'shop' | 'evacuator'
  final String serviceTypeId;
  final String? acceptedMasterId;
  final String? acceptedEvacuatorId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ServiceType? serviceType;
  final SosAcceptedMaster? acceptedMaster;
  final SosAcceptedEvacuator? acceptedEvacuator;
  final SosPayment? payment;
  final List<SosDispatchInfo> dispatches;
  // Usta tomonida ko'rsatish uchun (backend faqat getStatus'da beradi).
  final String customerName;
  final String customerPhone;
  final String vehiclePlate;
  final String vehicleLabel;

  SosRequest({
    required this.id,
    required this.status,
    this.dispatchMode = 'shop',
    required this.serviceTypeId,
    this.acceptedMasterId,
    this.acceptedEvacuatorId,
    required this.createdAt,
    required this.updatedAt,
    this.serviceType,
    this.acceptedMaster,
    this.acceptedEvacuator,
    this.payment,
    this.dispatches = const [],
    this.customerName = '',
    this.customerPhone = '',
    this.vehiclePlate = '',
    this.vehicleLabel = '',
  });

  factory SosRequest.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>? ?? {};
    final vehicle = json['vehicle'] as Map<String, dynamic>? ?? {};
    final make = (vehicle['make'] ?? '') as String;
    final model = (vehicle['model'] ?? '') as String;
    return SosRequest(
      id: json['id'] as String,
      status: (json['status'] ?? 'pending') as String,
      dispatchMode: (json['dispatchMode'] ?? json['dispatch_mode'] ?? 'shop') as String,
      serviceTypeId: (json['serviceTypeId'] ?? json['service_type_id'] ?? '') as String,
      acceptedMasterId: (json['acceptedMasterId'] ?? json['accepted_master_id']) as String?,
      acceptedEvacuatorId: (json['acceptedEvacuatorId'] ?? json['accepted_evacuator_id']) as String?,
      createdAt: DateTime.tryParse((json['createdAt'] ?? json['created_at'] ?? '') as String) ?? DateTime.now(),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? json['updated_at'] ?? '') as String) ?? DateTime.now(),
      serviceType: (json['serviceType'] ?? json['service_type']) != null
          ? ServiceType.fromJson({'id': '', ...(json['serviceType'] ?? json['service_type']) as Map<String, dynamic>})
          : null,
      acceptedMaster: (json['acceptedMaster'] ?? json['accepted_master']) != null
          ? SosAcceptedMaster.fromJson((json['acceptedMaster'] ?? json['accepted_master']) as Map<String, dynamic>)
          : null,
      acceptedEvacuator: (json['acceptedEvacuator'] ?? json['accepted_evacuator']) != null
          ? SosAcceptedEvacuator.fromJson(
              (json['acceptedEvacuator'] ?? json['accepted_evacuator']) as Map<String, dynamic>)
          : null,
      payment: json['payment'] != null ? SosPayment.fromJson(json['payment'] as Map<String, dynamic>) : null,
      dispatches: ((json['dispatches']) as List<dynamic>?)
              ?.map((e) => SosDispatchInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      customerName: (customer['fullName'] ?? customer['full_name'] ?? '') as String,
      customerPhone: (customer['phone'] ?? '') as String,
      vehiclePlate: (vehicle['plate'] ?? '') as String,
      vehicleLabel: '$make $model'.trim(),
    );
  }

  bool get isWaiting => status == 'pending' || status == 'dispatching';
  bool get isAccepted => status == 'accepted';
  bool get isOnTheWay => status == 'on_the_way';
  bool get isArrived => status == 'arrived';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isNoMasterFound => status == 'no_master_found';
  bool get isNoEvacuatorFound => status == 'no_evacuator_found';
  bool get isEvacuatorMode => dispatchMode == 'evacuator';
  bool get hasMaster => acceptedMasterId != null;
  bool get hasEvacuator => acceptedEvacuatorId != null;
  bool get hasAcceptedActor => hasMaster || hasEvacuator;
  bool get isActive => !isCompleted && !isCancelled && !isNoMasterFound && !isNoEvacuatorFound;
  bool get canCancel => isActive;
  bool get chatOpen => hasAcceptedActor && isActive;

  /// Xizmat yakunlangach ham, to'lov kutilayotgan bo'lsa hali "jonli"
  /// hisoblanadi — usta narx kiritganda mijoz WS/poll orqali darhol bilishi
  /// uchun (Faza 3.8). To'langach jonli kuzatuv to'xtaydi.
  bool get needsLiveUpdates => isActive || (isCompleted && payment?.status != 'paid');

  /// Nechta noyob nishonga (servis yoki evakuator) so'rov yuborilgani
  /// (mijozga "N ta qidirilmoqda" ko'rsatish uchun).
  int get dispatchedTargetCount =>
      dispatches.map((d) => d.shopId ?? d.evacuatorId).whereType<String>().toSet().length;
}

/// Usta kabinetida ko'rinadigan, hali javobsiz SOS so'rovi (ro'yxat elementi).
class SosIncomingRequest {
  final String dispatchId;
  final String sosRequestId;
  final int wave;
  final int distanceMeters;
  final DateTime sentAt;
  final ServiceType? serviceType;
  final Vehicle? vehicle;
  final String customerName;
  final String customerPhone;

  SosIncomingRequest({
    required this.dispatchId,
    required this.sosRequestId,
    required this.wave,
    required this.distanceMeters,
    required this.sentAt,
    this.serviceType,
    this.vehicle,
    this.customerName = '',
    this.customerPhone = '',
  });

  factory SosIncomingRequest.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>? ?? {};
    return SosIncomingRequest(
      dispatchId: (json['dispatchId'] ?? json['dispatch_id'] ?? '') as String,
      sosRequestId: (json['sosRequestId'] ?? json['sos_request_id'] ?? '') as String,
      wave: ((json['wave'] ?? 1) as num).toInt(),
      distanceMeters: ((json['distanceMeters'] ?? json['distance_meters'] ?? 0) as num).toInt(),
      sentAt: DateTime.tryParse((json['sentAt'] ?? json['sent_at'] ?? '') as String) ?? DateTime.now(),
      serviceType: json['serviceType'] != null
          ? ServiceType.fromJson({'id': '', ...json['serviceType'] as Map<String, dynamic>})
          : null,
      vehicle: json['vehicle'] != null ? Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>) : null,
      customerName: (customer['fullName'] ?? customer['full_name'] ?? '') as String,
      customerPhone: (customer['phone'] ?? '') as String,
    );
  }
}

class SosMessage {
  final String id;
  final String sosRequestId;
  final String senderUserId;
  final String body;
  final DateTime createdAt;

  SosMessage({
    required this.id,
    required this.sosRequestId,
    required this.senderUserId,
    required this.body,
    required this.createdAt,
  });

  factory SosMessage.fromJson(Map<String, dynamic> json) => SosMessage(
        id: json['id'] as String,
        sosRequestId: (json['sosRequestId'] ?? json['sos_request_id'] ?? '') as String,
        senderUserId: (json['senderUserId'] ?? json['sender_user_id'] ?? '') as String,
        body: (json['body'] ?? '') as String,
        createdAt: DateTime.tryParse((json['createdAt'] ?? json['created_at'] ?? '') as String) ?? DateTime.now(),
      );
}
