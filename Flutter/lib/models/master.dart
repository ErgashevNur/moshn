/// Ustaning bajaradigan xizmati (MasterServiceType join).
class MasterServiceRef {
  final String serviceTypeId;
  final String slug;
  final String nameUz;
  final String nameRu;

  MasterServiceRef({
    required this.serviceTypeId,
    this.slug = '',
    this.nameUz = '',
    this.nameRu = '',
  });

  factory MasterServiceRef.fromJson(Map<String, dynamic> j) {
    final st = j['serviceType'] as Map<String, dynamic>? ?? {};
    return MasterServiceRef(
      serviceTypeId: (j['serviceTypeId'] ?? j['service_type_id'] ?? '') as String,
      slug: (st['slug'] ?? '') as String,
      nameUz: (st['nameUz'] ?? st['name_uz'] ?? '') as String,
      nameRu: (st['nameRu'] ?? st['name_ru'] ?? '') as String,
    );
  }
}

class Master {
  final String id;
  final String shopId;
  final String userId;
  final String fullName;
  final String position;
  final String avatarUrl;
  final bool isActive;
  final double ratingAvg;
  final int ratingCount;
  final List<MasterServiceRef> serviceTypes;

  Master({
    required this.id,
    required this.shopId,
    required this.userId,
    required this.fullName,
    required this.position,
    required this.avatarUrl,
    required this.isActive,
    required this.ratingAvg,
    required this.ratingCount,
    this.serviceTypes = const [],
  });

  factory Master.fromJson(Map<String, dynamic> json) => Master(
        id: json['id'] as String,
        shopId: (json['shopId'] ?? json['shop_id'] ?? '') as String,
        userId: (json['userId'] ?? json['user_id'] ?? '') as String,
        fullName: (json['fullName'] ?? json['full_name'] ?? '') as String,
        position: (json['position'] ?? '') as String,
        avatarUrl: (json['avatarUrl'] ?? json['avatar_url'] ?? '') as String,
        isActive: (json['isActive'] ?? json['is_active'] ?? true) as bool,
        ratingAvg: ((json['ratingAvg'] ?? json['rating_avg'] ?? 0.0) as num).toDouble(),
        ratingCount: ((json['ratingCount'] ?? json['rating_count'] ?? 0) as num).toInt(),
        serviceTypes: ((json['serviceTypes'] ?? json['service_types']) as List<dynamic>?)
                ?.map((e) => MasterServiceRef.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  /// Usta hech qanday xizmat biriktirmagan bo'lsa — har qanday xizmatga
  /// mos deb hisoblaymiz (yakka usta / to'ldirilmagan holat uchun).
  bool offersService(String serviceTypeId) {
    if (serviceTypes.isEmpty) return true;
    return serviceTypes.any((s) => s.serviceTypeId == serviceTypeId);
  }
}
