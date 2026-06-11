import '../database/database_helper.dart';
import '../local_store_support.dart';
import '../models/member.dart';
import '../web_memory_store.dart';

class MemberDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insert(Member member) async {
    if (useLocalStore) {
      final savedMember = member.copyWith(id: WebMemoryStore.nextMemberId());
      WebMemoryStore.members.add(savedMember);
      await WebMemoryStore.persist();
      return savedMember.id!;
    }

    final db = await _dbHelper.database;
    final map = member.toMap();
    map.remove('id');
    return await db.insert('members', map);
  }

  Future<List<Member>> getAll() async {
    if (useLocalStore) {
      return List<Member>.from(WebMemoryStore.members);
    }

    final db = await _dbHelper.database;
    final maps = await db.query('members', orderBy: 'created_at ASC');
    return maps.map((map) => Member.fromMap(map)).toList();
  }

  Future<int> update(Member member) async {
    if (useLocalStore) {
      final index =
          WebMemoryStore.members.indexWhere((item) => item.id == member.id);
      if (index == -1) return 0;
      WebMemoryStore.members[index] = member;
      await WebMemoryStore.persist();
      return 1;
    }

    final db = await _dbHelper.database;
    return await db.update(
      'members',
      member.toMap(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  Future<int> delete(int id) async {
    if (useLocalStore) {
      for (var i = 0; i < WebMemoryStore.chores.length; i++) {
        final chore = WebMemoryStore.chores[i];
        if (chore.assignedMemberId == id) {
          WebMemoryStore.chores[i] = chore.copyWith(clearAssignedMember: true);
        }
      }
      final before = WebMemoryStore.members.length;
      WebMemoryStore.members.removeWhere((member) => member.id == id);
      await WebMemoryStore.persist();
      return before - WebMemoryStore.members.length;
    }

    final db = await _dbHelper.database;
    // Set assigned_member_id to null for chores assigned to this member
    await db.update(
      'chores',
      {'assigned_member_id': null},
      where: 'assigned_member_id = ?',
      whereArgs: [id],
    );
    return await db.delete('members', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAll() async {
    if (useLocalStore) {
      final count = WebMemoryStore.members.length;
      WebMemoryStore.members.clear();
      await WebMemoryStore.persist();
      return count;
    }

    final db = await _dbHelper.database;
    return await db.delete('members');
  }
}
