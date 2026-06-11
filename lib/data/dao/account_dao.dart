import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../database/database_helper.dart';
import '../local_store_support.dart';
import '../models/app_user.dart';
import '../models/household.dart';
import '../web_memory_store.dart';

class AccountDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insertUser(AppUser user) async {
    if (useLocalStore) {
      final saved = user.copyWith(id: WebMemoryStore.nextUserId());
      WebMemoryStore.users.add(saved);
      await WebMemoryStore.persist();
      return saved.id!;
    }

    final db = await _dbHelper.database;
    final map = user.toMap()..remove('id');
    return db.insert('app_users', map);
  }

  Future<AppUser?> getUserById(int id) async {
    if (useLocalStore) {
      try {
        return WebMemoryStore.users.firstWhere((user) => user.id == id);
      } catch (_) {
        return null;
      }
    }

    final db = await _dbHelper.database;
    final rows = await db.query('app_users', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : AppUser.fromMap(rows.first);
  }

  Future<AppUser?> getUserByEmail(String email) async {
    if (useLocalStore) {
      try {
        return WebMemoryStore.users.firstWhere((user) => user.email == email);
      } catch (_) {
        return null;
      }
    }

    final db = await _dbHelper.database;
    final rows = await db.query(
      'app_users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return rows.isEmpty ? null : AppUser.fromMap(rows.first);
  }

  Future<int> updateUser(AppUser user) async {
    if (useLocalStore) {
      final index =
          WebMemoryStore.users.indexWhere((item) => item.id == user.id);
      if (index == -1) return 0;
      WebMemoryStore.users[index] = user;
      await WebMemoryStore.persist();
      return 1;
    }

    final db = await _dbHelper.database;
    return db.update(
      'app_users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> setSession(int userId) async {
    if (useLocalStore) {
      WebMemoryStore.sessionUserId = userId;
      await WebMemoryStore.persist();
      return;
    }

    final db = await _dbHelper.database;
    await db.insert(
      'app_session',
      {'id': 1, 'user_id': userId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<AppUser?> getSessionUser() async {
    if (useLocalStore) {
      final id = WebMemoryStore.sessionUserId;
      return id == null ? null : getUserById(id);
    }

    final db = await _dbHelper.database;
    final rows = await db.query('app_session', where: 'id = 1');
    if (rows.isEmpty || rows.first['user_id'] == null) return null;
    return getUserById(rows.first['user_id'] as int);
  }

  Future<void> clearSession() async {
    if (useLocalStore) {
      WebMemoryStore.sessionUserId = null;
      await WebMemoryStore.persist();
      return;
    }

    final db = await _dbHelper.database;
    await db.delete('app_session');
  }

  Future<int> insertHousehold(Household household) async {
    if (useLocalStore) {
      final saved = household.copyWith(id: WebMemoryStore.nextHouseholdId());
      WebMemoryStore.households.add(saved);
      await WebMemoryStore.persist();
      return saved.id!;
    }

    final db = await _dbHelper.database;
    final map = household.toMap()..remove('id');
    return db.insert('households', map);
  }

  Future<Household?> getHouseholdById(int id) async {
    if (useLocalStore) {
      try {
        return WebMemoryStore.households.firstWhere((item) => item.id == id);
      } catch (_) {
        return null;
      }
    }

    final db = await _dbHelper.database;
    final rows = await db.query('households', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Household.fromMap(rows.first);
  }

  Future<Household?> getHouseholdByCode(String code) async {
    if (useLocalStore) {
      try {
        return WebMemoryStore.households
            .firstWhere((item) => item.inviteCode == code);
      } catch (_) {
        return null;
      }
    }

    final db = await _dbHelper.database;
    final rows = await db.query(
      'households',
      where: 'invite_code = ?',
      whereArgs: [code],
    );
    return rows.isEmpty ? null : Household.fromMap(rows.first);
  }
}
