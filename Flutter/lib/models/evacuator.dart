class Evacuator {
  final String id;
  final String userId;
  final String fullName;
  final String phone;
  final String vehiclePlate;
  final bool isActive;
  final bool isAvailable;
  final double ratingAvg;
  final int ratingCount;

  Evacuator({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.vehiclePlate,
    required this.isActive,
    required this.isAvailable,
    required this.ratingAvg,
    required this.ratingCount,
  });

  factory Evacuator.fromJson(Map<String, dynamic> json) => Evacuator(
        id: json['id'] as String,
        userId: (json['userId'] ?? json['user_id'] ?? '') as String,
        fullName: (json['fullName'] ?? json['full_name'] ?? '') as String,
        phone: (json['phone'] ?? '') as String,
        vehiclePlate: (json['vehiclePlate'] ?? json['vehicle_plate'] ?? '') as String,
        isActive: (json['isActive'] ?? json['is_active'] ?? true) as bool,
        isAvailable: (json['isAvailable'] ?? json['is_available'] ?? true) as bool,
        ratingAvg: ((json['ratingAvg'] ?? json['rating_avg'] ?? 0.0) as num).toDouble(),
        ratingCount: ((json['ratingCount'] ?? json['rating_count'] ?? 0) as num).toInt(),
      );
}
