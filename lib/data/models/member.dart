class Member {
  final int? id;
  final String name;
  final String colorHex;
  final String avatarType;
  final String? avatarValue;
  final int? householdId;
  final DateTime createdAt;

  const Member({
    this.id,
    required this.name,
    required this.colorHex,
    this.avatarType = 'initials',
    this.avatarValue,
    this.householdId,
    required this.createdAt,
  });

  Member copyWith({
    int? id,
    String? name,
    String? colorHex,
    String? avatarType,
    String? avatarValue,
    int? householdId,
    DateTime? createdAt,
    bool clearAvatarValue = false,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      avatarType: avatarType ?? this.avatarType,
      avatarValue: clearAvatarValue ? null : (avatarValue ?? this.avatarValue),
      householdId: householdId ?? this.householdId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color_hex': colorHex,
      'avatar_type': avatarType,
      'avatar_value': avatarValue,
      'household_id': householdId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'] as int?,
      name: map['name'] as String,
      colorHex: map['color_hex'] as String,
      avatarType: (map['avatar_type'] as String?) ?? 'initials',
      avatarValue: map['avatar_value'] as String?,
      householdId: map['household_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
