import 'package:flutter/foundation.dart';

import '../../data/models/member.dart';
import '../../domain/auth_service.dart';
import '../../domain/member_service.dart';

class MembersController extends ChangeNotifier {
  final MemberService _memberService;

  MembersController({MemberService? memberService})
      : _memberService = memberService ?? MemberService();

  List<Member> members = [];
  Map<int, int> choreCounts = {};
  bool isLoading = true;
  bool _isDisposed = false;

  Future<void> loadMembers() async {
    final loadedMembers = await _memberService.getAllMembers();
    final loadedCounts = <int, int>{};
    for (final member in loadedMembers) {
      if (member.id != null) {
        loadedCounts[member.id!] =
            await _memberService.getTotalChoreCount(member.id!);
      }
    }
    if (_isDisposed) return;

    members = loadedMembers;
    choreCounts = loadedCounts;
    isLoading = false;
    notifyListeners();
  }

  Future<void> addMember(Member member) async {
    await _memberService.addMember(member).timeout(const Duration(seconds: 10));
    await loadMembers();
  }

  Future<int> getActiveChoreCount(int memberId) {
    return _memberService.getActiveChoreCount(memberId);
  }

  Future<void> deleteMember(int memberId) async {
    await _memberService.deleteMember(memberId);
    await loadMembers();
  }

  Member memberForDisplay(Member member) {
    final user = AuthService.instance.currentUser;
    if (user == null || member.id != user.memberId) return member;
    return member.copyWith(
      name: user.displayName,
      colorHex: user.colorHex,
      avatarType: user.avatarType,
      avatarValue: user.avatarValue,
      clearAvatarValue: user.avatarValue == null,
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
