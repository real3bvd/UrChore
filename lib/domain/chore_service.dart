import '../data/repository/chore_repository.dart';
import '../data/models/chore.dart';
import 'auth_service.dart';

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
    return await _choreRepo.updateChore(chore);
  }

  /// Business logic: toggles chore completion status.
  /// When completing a recurring chore, automatically creates
  /// the next occurrence with an updated due date.
  Future<int> toggleComplete(Chore chore) async {
    if (chore.isCompleted) {
      return await _choreRepo.markPending(chore.id!);
    } else {
      final result = await _choreRepo.markComplete(chore.id!);

      // If the chore is recurring, auto-create the next instance
      if (chore.recurrence != 'none') {
        await _createNextRecurrence(chore);
      }

      return result;
    }
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
  Future<void> _createNextRecurrence(Chore chore) async {
    final baseDate = chore.dueDate ?? DateTime.now();
    DateTime nextDueDate;

    switch (chore.recurrence) {
      case 'daily':
        nextDueDate = baseDate.add(const Duration(days: 1));
        break;
      case 'weekly':
        nextDueDate = baseDate.add(const Duration(days: 7));
        break;
      case 'monthly':
        nextDueDate = DateTime(
          baseDate.year,
          baseDate.month + 1,
          baseDate.day,
        );
        break;
      default:
        return;
    }

    // Ensure the next due date is in the future
    final now = DateTime.now();
    while (nextDueDate.isBefore(now)) {
      switch (chore.recurrence) {
        case 'daily':
          nextDueDate = nextDueDate.add(const Duration(days: 1));
          break;
        case 'weekly':
          nextDueDate = nextDueDate.add(const Duration(days: 7));
          break;
        case 'monthly':
          nextDueDate = DateTime(
            nextDueDate.year,
            nextDueDate.month + 1,
            nextDueDate.day,
          );
          break;
      }
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

    await _choreRepo.addChore(nextChore);
  }
}
