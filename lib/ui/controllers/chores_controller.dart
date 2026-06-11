import 'package:flutter/foundation.dart';

import '../../data/models/chore.dart';
import '../../data/models/chore_category.dart';
import '../../data/models/member.dart';
import '../../domain/category_service.dart';
import '../../domain/chore_service.dart';
import '../../domain/member_service.dart';

class ChoresController extends ChangeNotifier {
  final ChoreService _choreService;
  final MemberService _memberService;
  final CategoryService _categoryService;

  ChoresController({
    ChoreService? choreService,
    MemberService? memberService,
    CategoryService? categoryService,
  })  : _choreService = choreService ?? ChoreService(),
        _memberService = memberService ?? MemberService(),
        _categoryService = categoryService ?? CategoryService();

  List<Chore> allChores = [];
  List<Member> members = [];
  Map<int, ChoreCategory> categoryMap = {};
  int selectedFilter = 1;
  bool isLoading = true;
  bool _isDisposed = false;

  Future<void> loadData() async {
    final chores = await _choreService.getAllChores();
    final loadedMembers = await _memberService.getAllMembers();
    final categories = await _categoryService.getAll();
    if (_isDisposed) return;

    final loadedCategoryMap = <int, ChoreCategory>{};
    for (final category in categories) {
      if (category.id != null) {
        loadedCategoryMap[category.id!] = category;
      }
    }

    allChores = chores;
    members = loadedMembers;
    categoryMap = loadedCategoryMap;
    isLoading = false;
    notifyListeners();
  }

  List<Chore> get filteredChores {
    switch (selectedFilter) {
      case 1:
        return allChores.where((chore) => !chore.isCompleted).toList();
      case 2:
        return allChores.where((chore) => chore.isCompleted).toList();
      default:
        return allChores;
    }
  }

  String get emptyMessage {
    switch (selectedFilter) {
      case 1:
        return 'No pending chores';
      case 2:
        return 'No completed chores';
      default:
        return 'No chores yet';
    }
  }

  void selectFilter(int filter) {
    if (selectedFilter == filter) return;
    selectedFilter = filter;
    notifyListeners();
  }

  Member? findMember(int? memberId) {
    if (memberId == null) return null;
    for (final member in members) {
      if (member.id == memberId) return member;
    }
    return null;
  }

  ChoreCategory? findCategory(int? categoryId) {
    if (categoryId == null) return null;
    return categoryMap[categoryId];
  }

  Future<ChoreToggleResult> toggleChore(Chore chore) async {
    final result = await _choreService.toggleComplete(chore);
    await loadData();
    return result;
  }

  Future<void> undoCompletion(
    Chore chore,
    ChoreToggleResult result,
  ) async {
    await _choreService.undoCompletion(chore, result);
    await loadData();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
