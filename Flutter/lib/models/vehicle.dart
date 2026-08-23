class Vehicle {
  final String id;
  final String plate;
  final String make;
  final String model;
  final int year;
  final String? color;
  final String? photoUrl;

  /// Joriy probeg, km. 0 — kiritilmagan.
  final int mileageKm;

  /// Keyingi TO qaysi probegda kerak, km. 0 — belgilanmagan.
  final int nextServiceKm;

  final String ownerId;
  final DateTime createdAt;

  Vehicle({
    required this.id,
    required this.plate,
    required this.make,
    required this.model,
    required this.year,
    this.color,
    this.photoUrl,
    this.mileageKm = 0,
    this.nextServiceKm = 0,
    required this.ownerId,
    required this.createdAt,
  });

  String get displayName {
    final parts = [if (make.isNotEmpty) make, if (model.isNotEmpty) model];
    return parts.isNotEmpty ? '${parts.join(' ')} · $plate' : plate;
  }

  /// Keyingi TO gacha necha km qolgani. `null` — ma'lumot yetarli emas
  /// (probeg yoki TO belgilanmagan), ya'ni kartada ko'rsatilmaydi.
  int? get kmToService {
    if (mileageKm <= 0 || nextServiceKm <= 0) return null;
    final left = nextServiceKm - mileageKm;
    return left > 0 ? left : 0;
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] as String,
        plate: (json['plate'] ?? json['current_plate'] ?? '') as String,
        make: json['make'] as String? ?? '',
        model: json['model'] as String? ?? '',
        year: (json['year'] as num?)?.toInt() ?? 0,
        color: json['color'] as String?,
        photoUrl: (json['photoUrl'] ?? json['photo_url']) as String?,
        mileageKm: ((json['mileageKm'] ?? json['mileage_km'] ?? 0) as num).toInt(),
        nextServiceKm:
            ((json['nextServiceKm'] ?? json['next_service_km'] ?? 0) as num).toInt(),
        ownerId: (json['ownerId'] ?? json['owner_id']) as String? ?? '',
        createdAt: DateTime.tryParse((json['createdAt'] ?? json['created_at'] ?? '') as String) ?? DateTime.now(),
      );
}
