enum UserRole { none, owner, service, admin }

class User {
  final String id;
  final String phone;
  final String name;
  final UserRole role;
  final String? email;
  final String? avatarUrl;
  final DateTime createdAt;

  User({
    required this.id,
    required this.phone,
    required this.name,
    required this.role,
    this.email,
    this.avatarUrl,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        phone: json['phone'] as String,
        name: (json['fullName'] ?? json['full_name'] ?? json['name'] ?? '') as String,
        role: _parseRole(json['role'] as String?),
        email: json['email'] as String?,
        avatarUrl: (json['avatarUrl'] ?? json['avatar_url']) as String?,
        createdAt: DateTime.tryParse((json['createdAt'] ?? json['created_at'] ?? '') as String) ?? DateTime.now(),
      );

  static UserRole _parseRole(String? r) {
    switch (r) {
      case 'owner':  return UserRole.owner;
      case 'service': return UserRole.service;
      case 'admin':  return UserRole.admin;
      default:       return UserRole.none;
    }
  }
}
