import 'vehicle.dart';

enum ServiceStatus { draft, created, confirmed, rejected, autoConfirmed }

class ServiceRecord {
  final String id;
  final String vehicleId;
  final Vehicle? vehicle;
  final String mechanicId;
  final String mechanicName;
  final String ownerId;
  final String ownerName;
  final DateTime serviceDate;
  final int? mileageKm;
  final String serviceType;
  final String description;
  final List<Map<String, dynamic>> partsUsed;
  final int priceUZS;
  final String notes;
  final ServiceStatus status;
  final List<String> photoBefore;
  final List<String> photoAfter;
  final DateTime createdAt;
  final DateTime? confirmedAt;

  ServiceRecord({
    required this.id,
    required this.vehicleId,
    this.vehicle,
    required this.mechanicId,
    required this.mechanicName,
    required this.ownerId,
    required this.ownerName,
    required this.serviceDate,
    this.mileageKm,
    required this.serviceType,
    required this.description,
    required this.partsUsed,
    required this.priceUZS,
    required this.notes,
    required this.status,
    required this.photoBefore,
    required this.photoAfter,
    required this.createdAt,
    this.confirmedAt,
  });

  /// Total cost shown to the user. Backend stores a single `price_uzs`.
  int get totalCost => priceUZS;

  /// Title for a vehicle this record belongs to, e.g. "Chevrolet Cobalt · 01A123BC".
  String get vehicleLabel {
    final v = vehicle;
    if (v == null) return '';
    final plate = v.plate.isEmpty ? '' : ' · ${v.plate}';
    return '${v.fullName}$plate';
  }

  factory ServiceRecord.fromJson(Map<String, dynamic> json) {
    final mechanicJson = json['mechanic'] as Map<String, dynamic>?;
    final mechanicUser = mechanicJson?['user'] as Map<String, dynamic>?;
    final ownerJson = json['owner'] as Map<String, dynamic>?;
    final vehicleJson = json['vehicle'] as Map<String, dynamic>?;

    return ServiceRecord(
      id: json['id'] as String,
      vehicleId: json['vehicle_id'] as String? ?? '',
      vehicle: (vehicleJson != null && vehicleJson['id'] != null)
          ? Vehicle.fromJson(vehicleJson)
          : null,
      mechanicId: json['mechanic_id'] as String? ?? '',
      mechanicName: (mechanicUser?['full_name'] as String?) ??
          (json['mechanic_name'] as String?) ??
          '',
      ownerId: json['owner_id'] as String? ?? '',
      ownerName: (ownerJson?['full_name'] as String?) ?? '',
      serviceDate: DateTime.tryParse(json['service_date'] ?? '') ??
          DateTime.tryParse(json['created_at'] ?? '') ??
          DateTime.now(),
      mileageKm: (json['mileage_km'] as num?)?.toInt(),
      serviceType: json['service_type'] as String? ?? '',
      description: json['description'] as String? ?? '',
      partsUsed: ((json['parts_used'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList(),
      priceUZS: (json['price_uzs'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String? ?? '',
      status: _parseStatus(json['status'] as String?),
      photoBefore: ((json['photo_before'] as List?) ?? []).cast<String>(),
      photoAfter: ((json['photo_after'] as List?) ?? []).cast<String>(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.tryParse(json['confirmed_at'])
          : null,
    );
  }

  static ServiceStatus _parseStatus(String? s) {
    switch (s) {
      case 'confirmed':
        return ServiceStatus.confirmed;
      case 'rejected':
        return ServiceStatus.rejected;
      case 'auto_confirmed':
        return ServiceStatus.autoConfirmed;
      case 'draft':
        return ServiceStatus.draft;
      default:
        return ServiceStatus.created;
    }
  }
}
