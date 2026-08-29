/// User model representing a system user (from Prisma User model)
class UserModel {
  final String id;
  final String? name;
  final String? email;
  final String? image;
  final String role; // USER or ADMIN
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    this.name,
    this.email,
    this.image,
    this.role = 'USER',
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String?,
      email: json['email'] as String?,
      image: json['image'] as String?,
      role: json['role'] as String? ?? 'USER',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'image': image,
      'role': role,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? image,
    String? role,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      image: image ?? this.image,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isAdmin => role == 'ADMIN';
  bool get isUser => role == 'USER';
}

/// Login request model
class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

/// Register request model
class RegisterRequest {
  final String name;
  final String email;
  final String password;

  const RegisterRequest({required this.name, required this.email, required this.password});

  Map<String, dynamic> toJson() => {'name': name, 'email': email, 'password': password};
}

/// Session model returned after authentication
class SessionModel {
  final UserModel user;
  final String token;
  final DateTime expiresAt;

  const SessionModel({required this.user, required this.token, required this.expiresAt});

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      user: UserModel.fromJson(json['user'] ?? {}),
      token: json['token'] as String? ?? '',
      expiresAt: DateTime.parse(json['expiresAt'] ?? DateTime.now().add(const Duration(days: 30)).toIso8601String()),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
