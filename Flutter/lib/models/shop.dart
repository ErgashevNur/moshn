class ShopServicePrice {
  final String serviceTypeId;
  final String slug;
  final String nameUz;
  final String nameRu;
  final int priceMin;
  final int priceMax;

  ShopServicePrice({
    required this.serviceTypeId,
    required this.slug,
    required this.nameUz,
    required this.nameRu,
    required this.priceMin,
    required this.priceMax,
  });

  factory ShopServicePrice.fromJson(Map<String, dynamic> j) {
    final st = j['serviceType'] as Map<String, dynamic>? ?? {};
    return ShopServicePrice(
      serviceTypeId: (j['serviceTypeId'] ?? j['service_type_id'] ?? '') as String,
      slug:     (st['slug'] ?? '') as String,
      nameUz:   (st['nameUz'] ?? st['name_uz'] ?? '') as String,
      nameRu:   (st['nameRu'] ?? st['name_ru'] ?? '') as String,
      priceMin: ((j['priceMin'] ?? j['price_min'] ?? 0) as num).toInt(),
      priceMax: ((j['priceMax'] ?? j['price_max'] ?? 0) as num).toInt(),
    );
  }

  String rangeText(String locale) {
    final mn = priceMin;
    final mx = priceMax;
    String fmt(int n) => n.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ');
    if (mn > 0 && mx > 0) return '${fmt(mn)} – ${fmt(mx)} so\'m';
    if (mn > 0) return 'от ${fmt(mn)} so\'m';
    if (mx > 0) return 'до ${fmt(mx)} so\'m';
    return '';
  }
}

class Shop {
  final String id;
  final String shopName;
  final String address;
  final double latitude;
  final double longitude;
  final String phone;
  final String workingHours;
  final List<String> serviceTypes;
  final String verificationStatus;
  final double ratingAvg;
  final int ratingCount;
  final int totalBookings;
  final double? distanceKm;
  final List<ShopServicePrice> servicePrices;

  Shop({
    required this.id,
    required this.shopName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.workingHours,
    required this.serviceTypes,
    required this.verificationStatus,
    required this.ratingAvg,
    required this.ratingCount,
    required this.totalBookings,
    this.distanceKm,
    this.servicePrices = const [],
  });

  factory Shop.fromJson(Map<String, dynamic> json) => Shop(
        id: json['id'] as String,
        shopName: (json['shopName'] ?? json['shop_name'] ?? '') as String,
        address: (json['address'] ?? '') as String,
        latitude: ((json['latitude'] ?? 0.0) as num).toDouble(),
        longitude: ((json['longitude'] ?? 0.0) as num).toDouble(),
        phone: (json['phone'] ?? '') as String,
        workingHours: (json['workingHours'] ?? json['working_hours'] ?? '') as String,
        serviceTypes: ((json['serviceTypes'] ?? json['service_types']) as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        verificationStatus:
            (json['verificationStatus'] ?? json['verification_status'] ?? 'pending') as String,
        ratingAvg: ((json['ratingAvg'] ?? json['rating_avg'] ?? 0.0) as num).toDouble(),
        ratingCount: ((json['ratingCount'] ?? json['rating_count'] ?? 0) as num).toInt(),
        totalBookings: ((json['totalBookings'] ?? json['total_bookings'] ?? 0) as num).toInt(),
        distanceKm: (json['distance_km'] ?? json['distanceKm']) != null
            ? ((json['distance_km'] ?? json['distanceKm']) as num).toDouble()
            : null,
        servicePrices: ((json['servicePrices'] ?? json['service_prices']) as List<dynamic>?)
                ?.map((e) => ShopServicePrice.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
