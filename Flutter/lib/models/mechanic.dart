class Mechanic {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final List<String> specialization;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double rating;
  final int completedJobs;
  final bool verified;
  final String? avatarUrl;
  final String? bio;

  Mechanic({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.specialization,
    this.address,
    this.latitude,
    this.longitude,
    required this.rating,
    required this.completedJobs,
    required this.verified,
    this.avatarUrl,
    this.bio,
  });

  factory Mechanic.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return Mechanic(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      // Name/phone/avatar live on the nested user; fall back to flat keys.
      name: (user?['full_name'] as String?) ??
          (json['name'] as String?) ??
          '',
      phone: (user?['phone'] as String?) ?? (json['phone'] as String?) ?? '',
      specialization:
          ((json['specialization'] as List?) ?? []).cast<String>(),
      address: (json['workshop_address'] ?? json['address']) as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      rating: (json['rating_avg'] ?? json['rating'] as num?) == null
          ? 0.0
          : ((json['rating_avg'] ?? json['rating']) as num).toDouble(),
      completedJobs:
          ((json['total_services'] ?? json['completed_jobs']) as num?)
                  ?.toInt() ??
              0,
      verified: json['verified'] as bool? ??
          (json['verification_status'] == 'verified'),
      avatarUrl: (user?['avatar_url'] as String?) ?? json['avatar_url'] as String?,
      bio: (json['workshop_name'] ?? json['bio']) as String?,
    );
  }
}
