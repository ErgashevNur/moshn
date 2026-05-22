class SosRequest {
  final String id;
  final String phone;
  final double latitude;
  final double longitude;
  final String? address;
  final String status; // new, in_progress, resolved, cancelled
  final String? adminNotes;
  final String? assignedMechanicName;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  SosRequest({
    required this.id,
    required this.phone,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.status,
    this.adminNotes,
    this.assignedMechanicName,
    this.createdAt,
    this.resolvedAt,
  });

  factory SosRequest.fromJson(Map<String, dynamic> j) {
    final mech = j['assigned_mechanic'] as Map<String, dynamic>?;
    final mechUser = mech?['user'] as Map<String, dynamic>?;
    final mechName = (mech?['workshop_name'] as String?)?.isNotEmpty == true
        ? mech!['workshop_name'] as String
        : mechUser?['full_name'] as String?;
    return SosRequest(
      id: j['id'] as String? ?? '',
      phone: j['phone'] as String? ?? '',
      latitude: (j['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (j['longitude'] as num?)?.toDouble() ?? 0,
      address: j['address'] as String?,
      status: j['status'] as String? ?? 'new',
      adminNotes: j['admin_notes'] as String?,
      assignedMechanicName: mechName,
      createdAt: DateTime.tryParse(j['created_at'] as String? ?? ''),
      resolvedAt: j['resolved_at'] != null
          ? DateTime.tryParse(j['resolved_at'] as String)
          : null,
    );
  }
}
