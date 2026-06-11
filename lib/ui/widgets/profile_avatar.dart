import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String name;
  final String avatarType;
  final String? avatarValue;
  final String colorHex;
  final double size;
  final bool showBorder;

  const ProfileAvatar({
    super.key,
    required this.name,
    this.avatarType = 'default',
    this.avatarValue,
    this.colorHex = '5C8B6E',
    this.size = 48,
    this.showBorder = false,
  });

  Color get _color => Color(int.parse('FF$colorHex', radix: 16));

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
        border: Border.all(
          color:
              showBorder ? color : Theme.of(context).colorScheme.outlineVariant,
          width: showBorder ? 2.5 : 1,
        ),
      ),
      child: ClipOval(child: _buildContent(context, color)),
    );
  }

  Widget _buildContent(BuildContext context, Color color) {
    switch (avatarType) {
      case 'initials':
        final initial =
            name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
        return Center(
          child: Text(
            initial,
            style: TextStyle(
              color: color,
              fontSize: size * 0.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      case 'hedgehog':
        if (avatarValue != null) {
          return Image.asset(
            avatarValue!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _defaultIcon(context),
          );
        }
        return _defaultIcon(context);
      case 'photo':
        final bytes = _decodePhoto();
        if (bytes != null) {
          return Image.memory(bytes, fit: BoxFit.cover);
        }
        return _defaultIcon(context);
      default:
        return _defaultIcon(context);
    }
  }

  Uint8List? _decodePhoto() {
    if (avatarValue == null || avatarValue!.isEmpty) return null;
    try {
      return base64Decode(avatarValue!);
    } catch (_) {
      return null;
    }
  }

  Widget _defaultIcon(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      alignment: Alignment.center,
      child: Icon(
        Icons.person,
        size: size * 0.62,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}
