class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    this.fullName,
    this.email,
    required this.role,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String username;
  final String? fullName;
  final String? email;
  final String role;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AppUser copyWith({
    String? id,
    String? username,
    String? fullName,
    String? email,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id']?.toString() ?? '',
      username: (map['username'] ?? '') as String,
      fullName: map['full_name'] as String?,
      email: map['email'] as String?,
      role: (map['role'] ?? 'staff') as String,
      isActive: map['is_active'] is bool
          ? map['is_active'] as bool
          : (map['is_active']?.toString().toLowerCase() == 'true'),
      createdAt: _tryParseDate(map['created_at']),
      updatedAt: _tryParseDate(map['updated_at']),
    );
  }
}

class AppUserDraft {
  AppUserDraft({
    required this.username,
    required this.password,
    this.fullName,
    this.email,
    this.role = 'staff',
    this.isActive = true,
  });

  final String username;
  final String password;
  final String? fullName;
  final String? email;
  final String role;
  final bool isActive;

  Map<String, dynamic> toMap(String passwordHash) {
    return <String, dynamic>{
      'username': username,
      'full_name': fullName,
      'email': email,
      'role': role,
      'is_active': isActive,
      'password_hash': passwordHash,
    }..removeWhere((key, value) => value == null);
  }

  AppUserDraft copyWith({
    String? username,
    String? password,
    String? fullName,
    String? email,
    String? role,
    bool? isActive,
  }) {
    return AppUserDraft(
      username: username ?? this.username,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }
}

DateTime? _tryParseDate(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}
