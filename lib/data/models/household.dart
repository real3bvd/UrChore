class Household {
  final int? id;
  final String name;
  final String inviteCode;
  final DateTime createdAt;

  const Household({
    this.id,
    required this.name,
    required this.inviteCode,
    required this.createdAt,
  });

  Household copyWith({
    int? id,
    String? name,
    String? inviteCode,
    DateTime? createdAt,
  }) {
    return Household(
      id: id ?? this.id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'invite_code': inviteCode,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Household.fromMap(Map<String, dynamic> map) {
    return Household(
      id: map['id'] as int?,
      name: map['name'] as String,
      inviteCode: map['invite_code'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
