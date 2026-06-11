import '../database/database_helper.dart';
import '../local_store_support.dart';
import '../models/chore_category.dart';
import '../web_memory_store.dart';

class CategoryDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<ChoreCategory>> getAll() async {
    if (useLocalStore) {
      return List<ChoreCategory>.from(WebMemoryStore.categories);
    }

    final db = await _dbHelper.database;
    final maps = await db.query('chore_categories', orderBy: 'id ASC');
    return maps.map((map) => ChoreCategory.fromMap(map)).toList();
  }

  Future<ChoreCategory?> getById(int id) async {
    if (useLocalStore) {
      try {
        return WebMemoryStore.categories.firstWhere((cat) => cat.id == id);
      } catch (_) {
        return null;
      }
    }

    final db = await _dbHelper.database;
    final maps = await db.query(
      'chore_categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ChoreCategory.fromMap(maps.first);
  }

  Future<int> insert(ChoreCategory category) async {
    if (useLocalStore) {
      final savedCategory =
          category.copyWith(id: WebMemoryStore.nextCategoryId());
      WebMemoryStore.categories.add(savedCategory);
      await WebMemoryStore.persist();
      return savedCategory.id!;
    }

    final db = await _dbHelper.database;
    final map = category.toMap();
    map.remove('id');
    return await db.insert('chore_categories', map);
  }

  Future<int> delete(int id) async {
    if (useLocalStore) {
      final before = WebMemoryStore.categories.length;
      WebMemoryStore.categories.removeWhere((cat) => cat.id == id);
      await WebMemoryStore.persist();
      return before - WebMemoryStore.categories.length;
    }

    final db = await _dbHelper.database;
    return await db
        .delete('chore_categories', where: 'id = ?', whereArgs: [id]);
  }
}
