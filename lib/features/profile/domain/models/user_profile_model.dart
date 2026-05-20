class UserProfileModel {
  final String id;
  final String name;
  final String email;
  final String level;
  final String role;
  final DateTime createdAt;

  UserProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.level,
    required this.role,
    required this.createdAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      level: json['level'] as String,
      role: json['role'] as String? ?? 'student',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'level': level,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
