import 'package:flutter/foundation.dart';

import '../../data/models/chore.dart';
import '../../data/models/chore_category.dart';
import '../../data/models/member.dart';
import '../../domain/auth_service.dart';
import '../../domain/category_service.dart';
import '../../domain/chore_service.dart';
import '../../domain/member_service.dart';

class HomeController extends ChangeNotifier {
  final ChoreService _choreService;
  final MemberService _memberService;
  final CategoryService _categoryService;

  HomeController({
    ChoreService? choreService,
    MemberService? memberService,
    CategoryService? categoryService,
  })  : _choreService = choreService ?? ChoreService(),
        _memberService = memberService ?? MemberService(),
        _categoryService = categoryService ?? CategoryService();

  List<Chore> assignedChores = [];
  List<Chore> unassignedChores = [];
  List<Chore> householdChores = [];
  List<Member> members = [];
  Map<int, ChoreCategory> categoryMap = {};
  bool isLoading = true;
  bool _isDisposed = false;

  Future<void> loadData() async {
    final chores = await _choreService.getAllChores();
    final loadedMembers = await _memberService.getAllMembers();
    final categories = await _categoryService.getAll();
    final memberId = AuthService.instance.currentUser?.memberId;
    if (_isDisposed) return;

    final loadedCategoryMap = <int, ChoreCategory>{};
    for (final category in categories) {
      if (category.id != null) {
        loadedCategoryMap[category.id!] = category;
      }
    }

    assignedChores = chores
        .where(
          (chore) =>
              memberId != null &&
              chore.assignedMemberId == memberId &&
              !chore.isCompleted,
        )
        .toList()
      ..sort(_compareChores);
    unassignedChores = chores
        .where((chore) => chore.assignedMemberId == null && !chore.isCompleted)
        .toList()
      ..sort(_compareChores);
    householdChores = chores;
    members = loadedMembers;
    categoryMap = loadedCategoryMap;
    isLoading = false;
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

  Future<void> claimChore(Chore chore) async {
    final memberId = AuthService.instance.currentUser?.memberId;
    if (memberId == null) return;
    await _choreService.updateChore(
      chore.copyWith(assignedMemberId: memberId),
    );
    await loadData();
  }

  DateTime get weekStart {
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day);
    return date.subtract(Duration(days: date.weekday - DateTime.monday));
  }

  DateTime get _weekEnd => weekStart.add(const Duration(days: 7));

  List<Chore> get weeklyHouseholdChores {
    return householdChores.where((chore) {
      final dueDate = chore.dueDate;
      if (dueDate == null) return false;
      return !dueDate.isBefore(weekStart) && dueDate.isBefore(_weekEnd);
    }).toList();
  }

  Set<int> get assignedChoreDays {
    final days = <int>{};
    for (final chore in assignedChores) {
      for (var index = 0; index < 7; index++) {
        final day = weekStart.add(Duration(days: index));
        if (chore.occursOn(day)) {
          days.add(day.weekday);
        }
      }
    }
    return days;
  }

  static int _compareChores(Chore first, Chore second) {
    if (first.isCompleted != second.isCompleted) {
      return first.isCompleted ? 1 : -1;
    }
    if (first.dueDate == null && second.dueDate == null) {
      return second.createdAt.compareTo(first.createdAt);
    }
    if (first.dueDate == null) return 1;
    if (second.dueDate == null) return -1;
    return first.dueDate!.compareTo(second.dueDate!);
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
