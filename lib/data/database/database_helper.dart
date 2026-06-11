import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('urchore.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color_hex TEXT NOT NULL,
        avatar_type TEXT NOT NULL DEFAULT 'initials',
        avatar_value TEXT,
        household_id INTEGER,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE chore_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon_name TEXT NOT NULL,
        color_hex TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE chores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        assigned_member_id INTEGER,
        due_date TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        category_id INTEGER,
        priority TEXT NOT NULL DEFAULT 'medium',
        recurrence TEXT NOT NULL DEFAULT 'none',
        household_id INTEGER,
        FOREIGN KEY (assigned_member_id) REFERENCES members(id) ON DELETE SET NULL,
        FOREIGN KEY (category_id) REFERENCES chore_categories(id) ON DELETE SET NULL
      )
    ''');

    await _createAccountTables(db);
    await _seedCategories(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS chore_categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          icon_name TEXT NOT NULL,
          color_hex TEXT NOT NULL
        )
      ''');
      await db.execute('ALTER TABLE chores ADD COLUMN category_id INTEGER');
      await db.execute(
          "ALTER TABLE chores ADD COLUMN priority TEXT NOT NULL DEFAULT 'medium'");
      await db.execute(
          "ALTER TABLE chores ADD COLUMN recurrence TEXT NOT NULL DEFAULT 'none'");
      await _seedCategories(db);
    }

    if (oldVersion < 3) {
      await db.execute(
          "ALTER TABLE members ADD COLUMN avatar_type TEXT NOT NULL DEFAULT 'initials'");
      await db.execute('ALTER TABLE members ADD COLUMN avatar_value TEXT');
      await db.execute('ALTER TABLE members ADD COLUMN household_id INTEGER');
      await db.execute('ALTER TABLE chores ADD COLUMN household_id INTEGER');
      await _createAccountTables(db);
    }
  }

  Future<void> _createAccountTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS households (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        invite_code TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        display_name TEXT NOT NULL,
        avatar_type TEXT NOT NULL DEFAULT 'default',
        avatar_value TEXT,
        color_hex TEXT NOT NULL DEFAULT '5C8B6E',
        household_id INTEGER,
        member_id INTEGER,
        role TEXT NOT NULL DEFAULT 'member',
        created_at TEXT NOT NULL,
        FOREIGN KEY (household_id) REFERENCES households(id) ON DELETE SET NULL,
        FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_session (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        user_id INTEGER,
        FOREIGN KEY (user_id) REFERENCES app_users(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _seedCategories(Database db) async {
    final categories = [
      {'name': 'Kitchen', 'icon_name': 'kitchen', 'color_hex': 'E07B54'},
      {'name': 'Bathroom', 'icon_name': 'bathroom', 'color_hex': '5B8DB8'},
      {'name': 'Bedroom', 'icon_name': 'bedroom', 'color_hex': '8B6BAE'},
      {
        'name': 'Living Room',
        'icon_name': 'living_room',
        'color_hex': '5C8B6E'
      },
      {'name': 'Garden', 'icon_name': 'garden', 'color_hex': '6B9E45'},
      {'name': 'Laundry', 'icon_name': 'laundry', 'color_hex': 'C4784E'},
      {'name': 'Garage', 'icon_name': 'garage', 'color_hex': '7A7A7A'},
      {'name': 'General', 'icon_name': 'general', 'color_hex': 'C2A24C'},
    ];

    for (final cat in categories) {
      await db.insert('chore_categories', cat);
    }
  }

  Future<void> deleteAllChores() async {
    final db = await database;
    await db.delete('chores');
  }

  Future<void> deleteEverything() async {
    final db = await database;
    await db.delete('chores');
    await db.delete('members');
  }
}
