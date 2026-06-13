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
        verificationStatus: (json['verificationStatus'] ?? json['verification_status'] ?? 'pending') as String,
        ratingAvg: ((json['ratingAvg'] ?? json['rating_avg'] ?? 0.0) as num).toDouble(),
        ratingCount: ((json['ratingCount'] ?? json['rating_count'] ?? 0) as num).toInt(),
        totalBookings: ((json['totalBookings'] ?? json['total_bookings'] ?? 0) as num).toInt(),
        distanceKm: (json['distance_km'] ?? json['distanceKm']) != null
            ? ((json['distance_km'] ?? json['distanceKm']) as num).toDouble()
            : null,
      );
}
