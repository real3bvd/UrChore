import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/app_user.dart';
import 'models/chore.dart';
import 'models/chore_category.dart';
import 'models/household.dart';
import 'models/member.dart';

class WebMemoryStore {
  static const _storageKey = 'urchore_web_store_v1';
  static final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  static bool persistenceEnabled = true;

  static int _nextMemberId = 1;
  static int _nextChoreId = 1;
  static int _nextCategoryId = 9;
  static int _nextUserId = 1;
  static int _nextHouseholdId = 1;

  static final List<Member> members = [];
  static final List<Chore> chores = [];
  static final List<AppUser> users = [];
  static final List<Household> households = [];
  static int? sessionUserId;
  static final List<ChoreCategory> categories = [
    const ChoreCategory(
      id: 1,
      name: 'Kitchen',
      iconName: 'kitchen',
      colorHex: 'E07B54',
    ),
    const ChoreCategory(
      id: 2,
      name: 'Bathroom',
      iconName: 'bathroom',
      colorHex: '5B8DB8',
    ),
    const ChoreCategory(
      id: 3,
      name: 'Bedroom',
      iconName: 'bedroom',
      colorHex: '8B6BAE',
    ),
    const ChoreCategory(
      id: 4,
      name: 'Living Room',
      iconName: 'living_room',
      colorHex: '5C8B6E',
    ),
    const ChoreCategory(
      id: 5,
      name: 'Garden',
      iconName: 'garden',
      colorHex: '6B9E45',
    ),
    const ChoreCategory(
      id: 6,
      name: 'Laundry',
      iconName: 'laundry',
      colorHex: 'C4784E',
    ),
    const ChoreCategory(
      id: 7,
      name: 'Garage',
      iconName: 'garage',
      colorHex: '7A7A7A',
    ),
    const ChoreCategory(
      id: 8,
      name: 'General',
      iconName: 'general',
      colorHex: 'C2A24C',
    ),
  ];

  static int nextMemberId() => _nextMemberId++;
  static int nextChoreId() => _nextChoreId++;
  static int nextCategoryId() => _nextCategoryId++;
  static int nextUserId() => _nextUserId++;
  static int nextHouseholdId() => _nextHouseholdId++;

  static Future<void> initialize() async {
    final raw = await _preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;

    final data = jsonDecode(raw) as Map<String, dynamic>;
    members
      ..clear()
      ..addAll(
        (data['members'] as List<dynamic>? ?? [])
            .map((item) => Member.fromMap(item as Map<String, dynamic>)),
      );
    chores
      ..clear()
      ..addAll(
        (data['chores'] as List<dynamic>? ?? [])
            .map((item) => Chore.fromMap(item as Map<String, dynamic>)),
      );
    users
      ..clear()
      ..addAll(
        (data['users'] as List<dynamic>? ?? [])
            .map((item) => AppUser.fromMap(item as Map<String, dynamic>)),
      );
    households
      ..clear()
      ..addAll(
        (data['households'] as List<dynamic>? ?? [])
            .map((item) => Household.fromMap(item as Map<String, dynamic>)),
      );
    final storedCategories = data['categories'] as List<dynamic>?;
    if (storedCategories != null && storedCategories.isNotEmpty) {
      categories
        ..clear()
        ..addAll(
          storedCategories.map(
            (item) => ChoreCategory.fromMap(item as Map<String, dynamic>),
          ),
        );
    }

    sessionUserId = data['session_user_id'] as int?;
    _nextMemberId = _nextId(members.map((item) => item.id));
    _nextChoreId = _nextId(chores.map((item) => item.id));
    _nextUserId = _nextId(users.map((item) => item.id));
    _nextHouseholdId = _nextId(households.map((item) => item.id));
    _nextCategoryId = _nextId(categories.map((item) => item.id));
  }

  static Future<void> persist() {
    if (!persistenceEnabled) return Future<void>.value();
    return _preferences.setString(
      _storageKey,
      jsonEncode({
        'members': members.map((item) => item.toMap()).toList(),
        'chores': chores.map((item) => item.toMap()).toList(),
        'users': users.map((item) => item.toMap()).toList(),
        'households': households.map((item) => item.toMap()).toList(),
        'categories': categories.map((item) => item.toMap()).toList(),
        'session_user_id': sessionUserId,
      }),
    );
  }

  static int _nextId(Iterable<int?> ids) {
    var highest = 0;
    for (final id in ids) {
      if (id != null && id > highest) highest = id;
    }
    return highest + 1;
  }
}
