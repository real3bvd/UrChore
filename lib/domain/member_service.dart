import '../data/repository/member_repository.dart';
import '../data/repository/chore_repository.dart';
import '../data/models/member.dart';
import 'auth_service.dart';

/// Service class that encapsulates business logic related to members.
/// Acts as an intermediary between the UI layer and the data layer,
/// handling cross-entity logic such as counting chores per member.
class MemberService {
  final MemberRepository _memberRepo = MemberRepository();
  final ChoreRepository _choreRepo = ChoreRepository();

  /// Adds a new member to the database.
  Future<int> addMember(Member member) async {
    return await _memberRepo.addMember(
      member.copyWith(
        householdId:
            member.householdId ?? AuthService.instance.currentUser?.householdId,
      ),
    );
  }

  /// Retrieves all members from the database.
  Future<List<Member>> getAllMembers() async {
    final members = await _memberRepo.getAllMembers();
    final householdId = AuthService.instance.currentUser?.householdId;
    if (householdId == null) return members;
    return members
        .where((member) => member.householdId == householdId)
        .toList();
  }

  /// Updates an existing member.
  Future<int> updateMember(Member member) async {
    return await _memberRepo.updateMember(member);
  }

  /// Deletes a member by their ID.
  Future<int> deleteMember(int id) async {
    return await _memberRepo.deleteMember(id);
  }

  /// Business logic: counts the number of active (uncompleted)
  /// chores currently assigned to a specific member.
  Future<int> getActiveChoreCount(int memberId) async {
    final chores = await _choreRepo.getChoresByMember(memberId);
    return chores.where((c) => !c.isCompleted).length;
  }

  /// Business logic: counts the total number of chores
  /// (both completed and pending) assigned to a specific member.
  Future<int> getTotalChoreCount(int memberId) async {
    final chores = await _choreRepo.getChoresByMember(memberId);
    return chores.length;
  }

  /// Deletes all members from the database.
  Future<int> deleteAllMembers() async {
    final members = await getAllMembers();
    final currentMemberId = AuthService.instance.currentUser?.memberId;
    var deleted = 0;
    for (final member in members) {
      if (member.id != null && member.id != currentMemberId) {
        deleted += await _memberRepo.deleteMember(member.id!);
      }
    }
    return deleted;
  }
}
