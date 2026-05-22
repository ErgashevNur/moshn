class Vehicle {
  final String id;
  final String vin;
  final String plate;
  final String make;
  final String model;
  final int year;
  final String? color;
  final String? photoUrl;
  final String ownerId;
  final DateTime createdAt;

  Vehicle({
    required this.id,
    required this.vin,
    required this.plate,
    required this.make,
    required this.model,
    required this.year,
    this.color,
    this.photoUrl,
    required this.ownerId,
    required this.createdAt,
  });

  String get fullName => '$make $model';

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] as String,
        vin: json['vin'] as String? ?? '',
        // Backend field is `current_plate`; accept `plate` as a fallback.
        plate: (json['current_plate'] ?? json['plate'] ?? '') as String,
        make: json['make'] as String? ?? '',
        model: json['model'] as String? ?? '',
        year: (json['year'] as num?)?.toInt() ?? 0,
        color: json['color'] as String?,
        photoUrl: json['photo_url'] as String?,
        ownerId: json['owner_id'] as String? ?? '',
        createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      );
}
