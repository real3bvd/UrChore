import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/chore.dart';
import '../../../data/models/chore_category.dart';
import '../../../data/models/member.dart';
import '../../theme/app_theme.dart';
import '../../theme/model_styles.dart';
import '../chore_card.dart';
import '../hedgehog_painter.dart';

class AssignedChoreSection extends StatelessWidget {
  final List<Chore> chores;
  final Member? Function(int? memberId) findMember;
  final ChoreCategory? Function(int? categoryId) findCategory;
  final ValueChanged<Chore> onToggle;
  final ValueChanged<Chore> onOpen;
  final VoidCallback? onSeeAll;

  const AssignedChoreSection({
    super.key,
    required this.chores,
    required this.findMember,
    required this.findCategory,
    required this.onToggle,
    required this.onOpen,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
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
                    '${chores.length} still to do',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onSeeAll,
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...List.generate(chores.length, (index) {
          final chore = chores[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < chores.length - 1 ? 10 : 0,
            ),
            child: ChoreCard(
              chore: chore,
              assignedMember: findMember(chore.assignedMemberId),
              category: findCategory(chore.categoryId),
              onToggle: () => onToggle(chore),
              onTap: () => onOpen(chore),
            ),
          );
        }),
      ],
    );
  }
}

class EmptyHomeContent extends StatelessWidget {
  final List<Chore> unassignedChores;
  final List<Chore> weeklyHouseholdChores;
  final ChoreCategory? Function(int? categoryId) findCategory;
  final VoidCallback onAddChore;
  final VoidCallback onBrowseTemplates;
  final ValueChanged<Chore> onClaim;
  final ValueChanged<Chore> onOpen;

  const EmptyHomeContent({
    super.key,
    required this.unassignedChores,
    required this.weeklyHouseholdChores,
    required this.findCategory,
    required this.onAddChore,
    required this.onBrowseTemplates,
    required this.onClaim,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EmptyAssignedState(
          onAddChore: onAddChore,
          onBrowseTemplates: onBrowseTemplates,
        ),
        if (unassignedChores.isNotEmpty) ...[
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
          ...unassignedChores.take(3).map(
                (chore) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _UnassignedChoreTile(
                    chore: chore,
                    category: findCategory(chore.categoryId),
                    onClaim: () => onClaim(chore),
                    onTap: () => onOpen(chore),
                  ),
                ),
              ),
        ],
        const SizedBox(height: 28),
        _HouseholdProgressCard(chores: weeklyHouseholdChores),
      ],
    );
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
