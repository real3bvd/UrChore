import '../dao/member_dao.dart';
import '../models/member.dart';

/// Repository that provides a clean data-access interface for members.
/// This layer abstracts the DAO and handles data operations only,
/// without any business logic.
class MemberRepository {
  final MemberDao _memberDao = MemberDao();

  Future<int> addMember(Member member) async {
    return await _memberDao.insert(member);
  }

  Future<List<Member>> getAllMembers() async {
    return await _memberDao.getAll();
  }

  Future<int> updateMember(Member member) async {
    return await _memberDao.update(member);
  }

  Future<int> deleteMember(int id) async {
    return await _memberDao.delete(id);
  }

  Future<int> deleteAll() async {
    return await _memberDao.deleteAll();
  }
}
