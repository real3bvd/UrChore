import 'package:flutter/material.dart';

class ChoreCategory {
  final int? id;
  final String name;
  final String iconName;
  final String colorHex;

  const ChoreCategory({
    this.id,
    required this.name,
    required this.iconName,
    required this.colorHex,
  });

  ChoreCategory copyWith({
    int? id,
    String? name,
    String? iconName,
    String? colorHex,
  }) {
    return ChoreCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_name': iconName,
      'color_hex': colorHex,
    };
  }

  factory ChoreCategory.fromMap(Map<String, dynamic> map) {
    return ChoreCategory(
      id: map['id'] as int?,
      name: map['name'] as String,
      iconName: map['icon_name'] as String,
      colorHex: map['color_hex'] as String,
    );
  }

  Color get color => Color(int.parse('FF$colorHex', radix: 16));

  IconData get icon => iconForName(iconName);

  static IconData iconForName(String name) {
    switch (name) {
      case 'kitchen':
        return Icons.kitchen_outlined;
      case 'bathroom':
        return Icons.bathtub_outlined;
      case 'bedroom':
        return Icons.bed_outlined;
      case 'living_room':
        return Icons.weekend_outlined;
      case 'garden':
        return Icons.yard_outlined;
      case 'laundry':
        return Icons.local_laundry_service_outlined;
      case 'garage':
        return Icons.garage_outlined;
      case 'general':
      default:
        return Icons.home_outlined;
    }
  }
}
