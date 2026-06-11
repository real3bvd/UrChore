import '../data/repository/chore_repository.dart';
import '../data/models/chore.dart';
import 'auth_service.dart';

class ChoreToggleResult {
  final bool completed;
  final DateTime? nextDueDate;
  final int? createdNextChoreId;

  const ChoreToggleResult({
    required this.completed,
    this.nextDueDate,
    this.createdNextChoreId,
  });
}

class _NextRecurrenceResult {
  final DateTime dueDate;
  final int? createdChoreId;

  const _NextRecurrenceResult(this.dueDate, this.createdChoreId);
}

/// Service class that encapsulates business logic related to chores.
/// Acts as an intermediary between the UI layer and the data layer,
/// ensuring that business rules are applied consistently.
class ChoreService {
  final ChoreRepository _choreRepo = ChoreRepository();

  /// Adds a new chore to the database.
  Future<int> addChore(Chore chore) async {
    return await _choreRepo.addChore(
      chore.copyWith(
        householdId:
            chore.householdId ?? AuthService.instance.currentUser?.householdId,
      ),
    );
  }

  /// Retrieves all chores from the database.
  Future<List<Chore>> getAllChores() async {
    final chores = await _choreRepo.getAllChores();
    final householdId = AuthService.instance.currentUser?.householdId;
    if (householdId == null) return chores;
    return chores.where((chore) => chore.householdId == householdId).toList();
  }

  /// Retrieves chores assigned to a specific member.
  Future<List<Chore>> getChoresByMember(int memberId) async {
    final chores = await _choreRepo.getChoresByMember(memberId);
    final householdId = AuthService.instance.currentUser?.householdId;
    if (householdId == null) return chores;
    return chores.where((chore) => chore.householdId == householdId).toList();
  }

  /// Retrieves all pending (uncompleted) chores.
  Future<List<Chore>> getPendingChores() async {
    final chores = await getAllChores();
    return chores.where((chore) => !chore.isCompleted).toList();
  }

  /// Retrieves all completed chores.
  Future<List<Chore>> getCompletedChores() async {
    final chores = await getAllChores();
    return chores.where((chore) => chore.isCompleted).toList();
  }

  /// Business logic: filters all chores to return only those
  /// that are due today or overdue and still pending.
  Future<List<Chore>> getTodayChores() async {
    final all = await getAllChores();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return all.where((chore) {
      if (chore.isCompleted) return false;
      if (chore.dueDate == null) return false;
      // Include overdue chores and chores due today
      return chore.dueDate!.isBefore(todayEnd);
    }).toList();
  }

  /// Updates an existing chore.
  Future<int> updateChore(Chore chore) async {
    return await _choreRepo.updateChore(
      chore.copyWith(
        householdId:
            chore.householdId ?? AuthService.instance.currentUser?.householdId,
      ),
    );
  }

  /// Business logic: toggles chore completion status.
  /// When completing a recurring chore, automatically creates
  /// the next occurrence with an updated due date.
  Future<ChoreToggleResult> toggleComplete(Chore chore) async {
    if (chore.isCompleted) {
      await _choreRepo.markPending(chore.id!);
      return const ChoreToggleResult(completed: false);
    }

    await _choreRepo.markComplete(chore.id!);

    if (chore.recurrence == 'none') {
      return const ChoreToggleResult(completed: true);
    }

    final next = await _createNextRecurrence(chore);
    return ChoreToggleResult(
      completed: true,
      nextDueDate: next?.dueDate,
      createdNextChoreId: next?.createdChoreId,
    );
  }

  Future<void> undoCompletion(
    Chore chore,
    ChoreToggleResult result,
  ) async {
    if (!result.completed || chore.id == null) return;

    if (result.createdNextChoreId != null) {
      await _choreRepo.deleteChore(result.createdNextChoreId!);
    }
    await _choreRepo.markPending(chore.id!);
  }

  /// Deletes a single chore by its ID.
  Future<int> deleteChore(int id) async {
    return await _choreRepo.deleteChore(id);
  }

  /// Retrieves aggregate statistics about all chores.
  Future<Map<String, int>> getStats() async {
    final chores = await getAllChores();
    final now = DateTime.now();
    return {
      'total': chores.length,
      'completed': chores.where((chore) => chore.isCompleted).length,
      'pending': chores.where((chore) => !chore.isCompleted).length,
      'overdue': chores
          .where((chore) =>
              !chore.isCompleted &&
              chore.dueDate != null &&
              chore.dueDate!.isBefore(now))
          .length,
    };
  }

  /// Deletes all chores from the database.
  Future<void> deleteAllChores() async {
    final chores = await getAllChores();
    for (final chore in chores) {
      if (chore.id != null) await _choreRepo.deleteChore(chore.id!);
    }
  }

  /// Creates the next instance of a recurring chore when it is completed.
  /// The new chore has the same title, description, category, priority,
  /// recurrence, and assignee — but with a future due date and isCompleted=false.
  Future<_NextRecurrenceResult?> _createNextRecurrence(Chore chore) async {
    final baseDate = chore.dueDate ?? DateTime.now();
    final firstNextDueDate = nextRecurrenceDate(chore.recurrence, baseDate);
    if (firstNextDueDate == null) return null;
    DateTime nextDueDate = firstNextDueDate;

    final now = DateTime.now();
    while (nextDueDate.isBefore(now)) {
      nextDueDate = nextRecurrenceDate(
        chore.recurrence,
        nextDueDate,
      )!;
    }

    final chores = await getAllChores();
    final alreadyExists = chores.any(
      (candidate) =>
          candidate.id != chore.id &&
          !candidate.isCompleted &&
          candidate.title == chore.title &&
          candidate.description == chore.description &&
          candidate.assignedMemberId == chore.assignedMemberId &&
          candidate.categoryId == chore.categoryId &&
          candidate.priority == chore.priority &&
          candidate.recurrence == chore.recurrence &&
          candidate.householdId == chore.householdId &&
          _sameDay(candidate.dueDate, nextDueDate),
    );
    if (alreadyExists) {
      return _NextRecurrenceResult(nextDueDate, null);
    }

    final nextChore = Chore(
      title: chore.title,
      description: chore.description,
      assignedMemberId: chore.assignedMemberId,
      dueDate: nextDueDate,
      isCompleted: false,
      createdAt: DateTime.now(),
      categoryId: chore.categoryId,
      priority: chore.priority,
      recurrence: chore.recurrence,
      householdId: chore.householdId,
    );

    final createdId = await _choreRepo.addChore(nextChore);
    return _NextRecurrenceResult(nextDueDate, createdId);
  }

  static DateTime? nextRecurrenceDate(
    String recurrence,
    DateTime baseDate,
  ) {
    switch (recurrence) {
      case 'daily':
        return baseDate.add(const Duration(days: 1));
      case 'weekly':
        return baseDate.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(
          baseDate.year,
          baseDate.month + 1,
          baseDate.day,
        );
      default:
        return null;
    }
  }

  static bool _sameDay(DateTime? first, DateTime second) {
    return first != null &&
        first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}
