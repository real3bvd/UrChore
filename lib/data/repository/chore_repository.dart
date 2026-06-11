import '../dao/chore_dao.dart';
import '../models/chore.dart';

/// Repository that provides a clean data-access interface for chores.
/// This layer abstracts the DAO and handles data operations only,
/// without any business logic.
class ChoreRepository {
  final ChoreDao _choreDao = ChoreDao();

  Future<int> addChore(Chore chore) async {
    return await _choreDao.insert(chore);
  }

  Future<List<Chore>> getAllChores() async {
    return await _choreDao.getAll();
  }

  Future<List<Chore>> getChoresByMember(int memberId) async {
    return await _choreDao.getByMember(memberId);
  }

  Future<List<Chore>> getPendingChores() async {
    return await _choreDao.getPending();
  }

  Future<List<Chore>> getCompletedChores() async {
    return await _choreDao.getCompleted();
  }

  Future<int> updateChore(Chore chore) async {
    return await _choreDao.update(chore);
  }

  Future<int> markComplete(int id) async {
    return await _choreDao.markComplete(id);
  }

  Future<int> markPending(int id) async {
    return await _choreDao.markPending(id);
  }

  Future<int> deleteChore(int id) async {
    return await _choreDao.delete(id);
  }

  Future<Map<String, int>> getStats() async {
    return await _choreDao.getStats();
  }

  Future<int> deleteAll() async {
    return await _choreDao.deleteAll();
  }
}
