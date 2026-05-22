enum UserRole { owner, mechanic, admin }

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
        name: (json['full_name'] ?? json['name'] ?? '') as String,
        role: _parseRole(json['role'] as String?),
        email: json['email'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      );

  static UserRole _parseRole(String? r) {
    switch (r) {
      case 'mechanic':
        return UserRole.mechanic;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.owner;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'name': name,
        'role': role.name,
        'email': email,
        'avatar_url': avatarUrl,
        'created_at': createdAt.toIso8601String(),
      };
}
