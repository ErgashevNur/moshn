class Vehicle {
  final String id;
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
    required this.plate,
    required this.make,
    required this.model,
    required this.year,
    this.color,
    this.photoUrl,
    required this.ownerId,
    required this.createdAt,
  });

  String get displayName {
    final parts = [if (make.isNotEmpty) make, if (model.isNotEmpty) model];
    return parts.isNotEmpty ? '${parts.join(' ')} · $plate' : plate;
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] as String,
        plate: (json['plate'] ?? json['current_plate'] ?? '') as String,
        make: json['make'] as String? ?? '',
        model: json['model'] as String? ?? '',
        year: (json['year'] as num?)?.toInt() ?? 0,
        color: json['color'] as String?,
        photoUrl: json['photo_url'] as String?,
        ownerId: json['owner_id'] as String? ?? '',
        createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      );
}
