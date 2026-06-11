import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/chore.dart';
import '../../data/models/chore_category.dart';
import '../../data/models/member.dart';
import '../../domain/auth_service.dart';
import '../../domain/category_service.dart';
import '../../domain/chore_service.dart';
import '../../domain/member_service.dart';
import '../theme/app_theme.dart';
import '../widgets/chore_card.dart';
import '../widgets/hedgehog_painter.dart';
import 'add_edit_chore_screen.dart';
import 'chore_template_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToChores;

  const HomeScreen({super.key, this.onNavigateToChores});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ChoreService _choreService = ChoreService();
  final MemberService _memberService = MemberService();
  final CategoryService _categoryService = CategoryService();

  List<Chore> _assignedChores = [];
  List<Chore> _unassignedChores = [];
  List<Chore> _householdChores = [];
  List<Member> _members = [];
  Map<int, ChoreCategory> _categoryMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final chores = await _choreService.getAllChores();
    final members = await _memberService.getAllMembers();
    final categories = await _categoryService.getAll();
    final memberId = AuthService.instance.currentUser?.memberId;

    final categoryMap = <int, ChoreCategory>{};
    for (final category in categories) {
      if (category.id != null) categoryMap[category.id!] = category;
    }

    final assigned = chores
        .where(
          (chore) =>
              memberId != null &&
              chore.assignedMemberId == memberId &&
              !chore.isCompleted,
        )
        .toList()
      ..sort(_compareChores);
    final unassigned = chores
        .where((chore) => chore.assignedMemberId == null && !chore.isCompleted)
        .toList()
      ..sort(_compareChores);

    if (!mounted) return;
    setState(() {
      _assignedChores = assigned;
      _unassignedChores = unassigned;
      _householdChores = chores;
      _members = members;
      _categoryMap = categoryMap;
      _isLoading = false;
    });
  }

  static int _compareChores(Chore a, Chore b) {
    if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
    if (a.dueDate == null && b.dueDate == null) {
      return b.createdAt.compareTo(a.createdAt);
    }
    if (a.dueDate == null) return 1;
    if (b.dueDate == null) return -1;
    return a.dueDate!.compareTo(b.dueDate!);
  }

  Member? _findMember(int? memberId) {
    if (memberId == null) return null;
    try {
      return _members.firstWhere((member) => member.id == memberId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _toggleChore(Chore chore) async {
    final result = await _choreService.toggleComplete(chore);
    await _loadData();
    if (!mounted || !result.completed) return;

    final message = result.nextDueDate == null
        ? '${chore.title} completed. Nice work!'
        : '${chore.title} completed. Next: '
            '${DateFormat('EEE, MMM d').format(result.nextDueDate!)}.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await _choreService.undoCompletion(chore, result);
            await _loadData();
          },
        ),
      ),
    );
  }

  Future<void> _openEditChore(Chore chore) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditChoreScreen(chore: chore),
      ),
    );
    if (result == true) await _loadData();
  }

  Future<void> _openAddChore() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditChoreScreen(
          prefilledMemberId: AuthService.instance.currentUser?.memberId,
        ),
      ),
    );
    if (result == true) await _loadData();
  }

  Future<void> _openTemplates() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ChoreTemplateScreen(
          prefilledMemberId: AuthService.instance.currentUser?.memberId,
        ),
      ),
    );
    if (result == true) await _loadData();
  }

  Future<void> _claimChore(Chore chore) async {
    final memberId = AuthService.instance.currentUser?.memberId;
    if (memberId == null) return;
    await _choreService.updateChore(
      chore.copyWith(assignedMemberId: memberId),
    );
    await _loadData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${chore.title} is now assigned to you.')),
    );
  }

  DateTime get _weekStart {
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day);
    return date.subtract(Duration(days: date.weekday - DateTime.monday));
  }

  DateTime get _weekEnd => _weekStart.add(const Duration(days: 7));

  List<Chore> get _weeklyHouseholdChores {
    return _householdChores.where((chore) {
      final dueDate = chore.dueDate;
      if (dueDate == null) return false;
      return !dueDate.isBefore(_weekStart) && dueDate.isBefore(_weekEnd);
    }).toList();
  }

  Set<int> get _assignedChoreDays {
    final days = <int>{};
    for (final chore in _assignedChores) {
      for (var index = 0; index < 7; index++) {
        final day = _weekStart.add(Duration(days: index));
        if (chore.occursOn(day)) {
          days.add(day.weekday);
        }
      }
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final userName =
        AuthService.instance.currentUser?.displayName.trim() ?? 'there';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 104),
            children: [
              _GreetingHeader(
                greeting: 'Hey $userName',
                date: DateFormat('EEEE, MMM d').format(now),
              ),
              const SizedBox(height: 24),
              _WeeklyCalendarStrip(
                weekStart: _weekStart,
                choreDays: _assignedChoreDays,
                today: now,
              ),
              const SizedBox(height: 28),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 72),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_assignedChores.isEmpty)
                _buildEmptyHome()
              else
                _buildAssignedChores(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add chore',
        onPressed: _openAddChore,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAssignedChores() {
    final pendingCount = _assignedChores.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your chores',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    pendingCount == 0
                        ? 'Everything assigned to you is complete.'
                        : '$pendingCount still to do',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: widget.onNavigateToChores,
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...List.generate(_assignedChores.length, (index) {
          final chore = _assignedChores[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < _assignedChores.length - 1 ? 10 : 0,
            ),
            child: ChoreCard(
              chore: chore,
              assignedMember: _findMember(chore.assignedMemberId),
              category: chore.categoryId == null
                  ? null
                  : _categoryMap[chore.categoryId],
              onToggle: () => _toggleChore(chore),
              onTap: () => _openEditChore(chore),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEmptyHome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EmptyAssignedState(
          onAddChore: _openAddChore,
          onBrowseTemplates: _openTemplates,
        ),
        if (_unassignedChores.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text(
            'Unassigned chores',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Pick one to help your household.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          ..._unassignedChores.take(3).map(
                (chore) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _UnassignedChoreTile(
                    chore: chore,
                    category: chore.categoryId == null
                        ? null
                        : _categoryMap[chore.categoryId],
                    onClaim: () => _claimChore(chore),
                    onTap: () => _openEditChore(chore),
                  ),
                ),
              ),
        ],
        const SizedBox(height: 28),
        _HouseholdProgressCard(chores: _weeklyHouseholdChores),
      ],
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  final String greeting;
  final String date;

  const _GreetingHeader({
    required this.greeting,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 4),
              Text(
                date,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
        const HedgehogWidget(
          size: 64,
          activity: HedgehogActivity.waving,
        ),
      ],
    );
  }
}

class _WeeklyCalendarStrip extends StatelessWidget {
  final DateTime weekStart;
  final Set<int> choreDays;
  final DateTime today;

  const _WeeklyCalendarStrip({
    required this.weekStart,
    required this.choreDays,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: List.generate(7, (index) {
          final day = weekStart.add(Duration(days: index));
          final isToday = _sameDay(day, today);
          final hasChore = choreDays.contains(day.weekday);

          return Expanded(
            child: Column(
              children: [
                Text(
                  DateFormat('E').format(day),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isToday
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 7),
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isToday
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${day.day}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isToday
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight:
                              isToday ? FontWeight.w700 : FontWeight.w500,
                        ),
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  key: hasChore
                      ? ValueKey(
                          'chore-dot-${DateFormat('yyyy-MM-dd').format(day)}',
                        )
                      : null,
                  duration: const Duration(milliseconds: 180),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: hasChore
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _EmptyAssignedState extends StatelessWidget {
  final VoidCallback onAddChore;
  final VoidCallback onBrowseTemplates;

  const _EmptyAssignedState({
    required this.onAddChore,
    required this.onBrowseTemplates,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          const HedgehogWidget(
            size: 68,
            activity: HedgehogActivity.mopping,
          ),
          const SizedBox(height: 12),
          Text(
            'Nothing assigned to you yet',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'A tidy home starts with one small chore. Add one now or choose '
            'a ready-made task to get moving.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onAddChore,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add chore'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onBrowseTemplates,
                  icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                  label: const Text('Templates'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnassignedChoreTile extends StatelessWidget {
  final Chore chore;
  final ChoreCategory? category;
  final VoidCallback onClaim;
  final VoidCallback onTap;

  const _UnassignedChoreTile({
    required this.chore,
    required this.category,
    required this.onClaim,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color:
                      (category?.color ?? Theme.of(context).colorScheme.primary)
                          .withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  category?.icon ?? Icons.home_outlined,
                  size: 18,
                  color:
                      category?.color ?? Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chore.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _dueLabel(chore),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: chore.isOverdue
                                ? AppColors.overdue
                                : Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onClaim,
                child: const Text('Claim'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _dueLabel(Chore chore) {
    if (chore.dueDate == null) return 'No due date';
    return 'Due ${DateFormat('MMM d').format(chore.dueDate!)}';
  }
}

class _HouseholdProgressCard extends StatelessWidget {
  final List<Chore> chores;

  const _HouseholdProgressCard({required this.chores});

  @override
  Widget build(BuildContext context) {
    final completed = chores.where((chore) => chore.isCompleted).length;
    final progress = chores.isEmpty ? 0.0 : completed / chores.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.groups_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Household progress',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      chores.isEmpty
                          ? 'No household chores are due this week.'
                          : '$completed of ${chores.length} chores completed this week',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
