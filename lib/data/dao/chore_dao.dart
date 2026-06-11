import '../database/database_helper.dart';
import '../local_store_support.dart';
import '../models/chore.dart';
import '../web_memory_store.dart';

class ChoreDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insert(Chore chore) async {
    if (useLocalStore) {
      final savedChore = chore.copyWith(id: WebMemoryStore.nextChoreId());
      WebMemoryStore.chores.add(savedChore);
      await WebMemoryStore.persist();
      return savedChore.id!;
    }

    final db = await _dbHelper.database;
    final map = chore.toMap();
    map.remove('id');
    return await db.insert('chores', map);
  }

  Future<List<Chore>> getAll() async {
    if (useLocalStore) {
      final chores = List<Chore>.from(WebMemoryStore.chores);
      chores.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return chores;
    }

    final db = await _dbHelper.database;
    final maps = await db.query('chores', orderBy: 'created_at DESC');
    return maps.map((map) => Chore.fromMap(map)).toList();
  }

  Future<List<Chore>> getByMember(int memberId) async {
    if (useLocalStore) {
      final chores = WebMemoryStore.chores
          .where((chore) => chore.assignedMemberId == memberId)
          .toList();
      chores.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return chores;
    }

    final db = await _dbHelper.database;
    final maps = await db.query(
      'chores',
      where: 'assigned_member_id = ?',
      whereArgs: [memberId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Chore.fromMap(map)).toList();
  }

  Future<List<Chore>> getPending() async {
    if (useLocalStore) {
      final chores =
          WebMemoryStore.chores.where((chore) => !chore.isCompleted).toList();
      chores.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return chores;
    }

    final db = await _dbHelper.database;
    final maps = await db.query(
      'chores',
      where: 'is_completed = 0',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Chore.fromMap(map)).toList();
  }

  Future<List<Chore>> getCompleted() async {
    if (useLocalStore) {
      final chores =
          WebMemoryStore.chores.where((chore) => chore.isCompleted).toList();
      chores.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return chores;
    }

    final db = await _dbHelper.database;
    final maps = await db.query(
      'chores',
      where: 'is_completed = 1',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Chore.fromMap(map)).toList();
  }

  Future<int> update(Chore chore) async {
    if (useLocalStore) {
      final index =
          WebMemoryStore.chores.indexWhere((item) => item.id == chore.id);
      if (index == -1) return 0;
      WebMemoryStore.chores[index] = chore;
      await WebMemoryStore.persist();
      return 1;
    }

    final db = await _dbHelper.database;
    return await db.update(
      'chores',
      chore.toMap(),
      where: 'id = ?',
      whereArgs: [chore.id],
    );
  }

  Future<int> markComplete(int id) async {
    if (useLocalStore) {
      final index = WebMemoryStore.chores.indexWhere((chore) => chore.id == id);
      if (index == -1) return 0;
      WebMemoryStore.chores[index] =
          WebMemoryStore.chores[index].copyWith(isCompleted: true);
      await WebMemoryStore.persist();
      return 1;
    }

    final db = await _dbHelper.database;
    return await db.update(
      'chores',
      {'is_completed': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> markPending(int id) async {
    if (useLocalStore) {
      final index = WebMemoryStore.chores.indexWhere((chore) => chore.id == id);
      if (index == -1) return 0;
      WebMemoryStore.chores[index] =
          WebMemoryStore.chores[index].copyWith(isCompleted: false);
      await WebMemoryStore.persist();
      return 1;
    }

    final db = await _dbHelper.database;
    return await db.update(
      'chores',
      {'is_completed': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) async {
    if (useLocalStore) {
      final before = WebMemoryStore.chores.length;
      WebMemoryStore.chores.removeWhere((chore) => chore.id == id);
      await WebMemoryStore.persist();
      return before - WebMemoryStore.chores.length;
    }

    final db = await _dbHelper.database;
    return await db.delete('chores', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, int>> getStats() async {
    if (useLocalStore) {
      final now = DateTime.now();
      final total = WebMemoryStore.chores.length;
      final completed =
          WebMemoryStore.chores.where((chore) => chore.isCompleted).length;
      final pending =
          WebMemoryStore.chores.where((chore) => !chore.isCompleted).length;
      final overdue = WebMemoryStore.chores
          .where((chore) =>
              !chore.isCompleted &&
              chore.dueDate != null &&
              chore.dueDate!.isBefore(now))
          .length;

      return {
        'total': total,
        'completed': completed,
        'pending': pending,
        'overdue': overdue,
      };
    }

    final db = await _dbHelper.database;
    final all = await db.rawQuery('SELECT COUNT(*) as count FROM chores');
    final completed = await db.rawQuery(
        'SELECT COUNT(*) as count FROM chores WHERE is_completed = 1');
    final pending = await db.rawQuery(
        'SELECT COUNT(*) as count FROM chores WHERE is_completed = 0');
    final overdue = await db.rawQuery(
        'SELECT COUNT(*) as count FROM chores WHERE is_completed = 0 AND due_date IS NOT NULL AND due_date < ?',
        [DateTime.now().toIso8601String()]);

    return {
      'total': (all.first['count'] as int?) ?? 0,
      'completed': (completed.first['count'] as int?) ?? 0,
      'pending': (pending.first['count'] as int?) ?? 0,
      'overdue': (overdue.first['count'] as int?) ?? 0,
    };
  }

  Future<int> deleteAll() async {
    if (useLocalStore) {
      final count = WebMemoryStore.chores.length;
      WebMemoryStore.chores.clear();
      await WebMemoryStore.persist();
      return count;
    }

    final db = await _dbHelper.database;
    return await db.delete('chores');
  }
}
