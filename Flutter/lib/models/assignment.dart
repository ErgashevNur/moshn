/// Ustaga yo'naltirilgan so'rov — SOS yoki tamirlash. Mijoz ma'lumotlari bilan.
enum AssignmentKind { sos, repair }

class Assignment {
  final String id;
  final AssignmentKind kind;
  final String clientName;
  final String phone;
  final String status;
  final DateTime? createdAt;

  // SOS uchun
  final double? latitude;
  final double? longitude;
  final String? address;

  // Tamirlash uchun
  final String? carInfo;
  final String? description;

  Assignment({
    required this.id,
    required this.kind,
    required this.clientName,
    required this.phone,
    required this.status,
    this.createdAt,
    this.latitude,
    this.longitude,
    this.address,
    this.carInfo,
    this.description,
  });

  factory Assignment.sos(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>?;
    return Assignment(
      id: j['id'] as String? ?? '',
      kind: AssignmentKind.sos,
      clientName: (user?['full_name'] as String?) ?? '',
      phone: j['phone'] as String? ?? '',
      status: j['status'] as String? ?? '',
      createdAt: DateTime.tryParse(j['created_at'] as String? ?? ''),
      latitude: (j['latitude'] as num?)?.toDouble(),
      longitude: (j['longitude'] as num?)?.toDouble(),
      address: j['address'] as String?,
    );
  }

  factory Assignment.repair(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>?;
    return Assignment(
      id: j['id'] as String? ?? '',
      kind: AssignmentKind.repair,
      clientName: (user?['full_name'] as String?) ?? '',
      phone: j['phone'] as String? ?? '',
      status: j['status'] as String? ?? '',
      createdAt: DateTime.tryParse(j['created_at'] as String? ?? ''),
      carInfo: j['car_info'] as String?,
      description: j['description'] as String?,
    );
  }
}
