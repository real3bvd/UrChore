import 'package:flutter/material.dart';
import '../../data/models/member.dart';
import 'profile_avatar.dart';

class MemberAvatar extends StatelessWidget {
  final Member member;
  final double size;
  final bool showBorder;

  const MemberAvatar({
    super.key,
    required this.member,
    this.size = 36.0,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileAvatar(
      name: member.name,
      avatarType: member.avatarType,
      avatarValue: member.avatarValue,
      colorHex: member.colorHex,
      size: size,
      showBorder: showBorder,
    );
  }
}
