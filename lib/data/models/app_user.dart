class AppUser {
  final int? id;
  final String email;
  final String passwordHash;
  final String displayName;
  final String avatarType;
  final String? avatarValue;
  final String colorHex;
  final int? householdId;
  final int? memberId;
  final String role;
  final DateTime createdAt;

  const AppUser({
    this.id,
    required this.email,
    required this.passwordHash,
    required this.displayName,
    this.avatarType = 'default',
    this.avatarValue,
    this.colorHex = '5C8B6E',
    this.householdId,
    this.memberId,
    this.role = 'member',
    required this.createdAt,
  });

  AppUser copyWith({
    int? id,
    String? email,
    String? passwordHash,
    String? displayName,
    String? avatarType,
    String? avatarValue,
    String? colorHex,
    int? householdId,
    int? memberId,
    String? role,
    DateTime? createdAt,
    bool clearAvatarValue = false,
    bool clearHousehold = false,
    bool clearMember = false,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      displayName: displayName ?? this.displayName,
      avatarType: avatarType ?? this.avatarType,
      avatarValue: clearAvatarValue ? null : (avatarValue ?? this.avatarValue),
      colorHex: colorHex ?? this.colorHex,
      householdId: clearHousehold ? null : (householdId ?? this.householdId),
      memberId: clearMember ? null : (memberId ?? this.memberId),
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password_hash': passwordHash,
      'display_name': displayName,
      'avatar_type': avatarType,
      'avatar_value': avatarValue,
      'color_hex': colorHex,
      'household_id': householdId,
      'member_id': memberId,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as int?,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String,
      displayName: map['display_name'] as String,
      avatarType: (map['avatar_type'] as String?) ?? 'default',
      avatarValue: map['avatar_value'] as String?,
      colorHex: (map['color_hex'] as String?) ?? '5C8B6E',
      householdId: map['household_id'] as int?,
      memberId: map['member_id'] as int?,
      role: (map['role'] as String?) ?? 'member',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
