import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/chore_category.dart';
import '../../../data/models/member.dart';
import '../../theme/app_theme.dart';
import '../../theme/model_styles.dart';
import '../member_avatar.dart';

class CategorySelector extends StatelessWidget {
  final List<ChoreCategory> categories;
  final int? selectedCategoryId;
  final ValueChanged<int?> onSelected;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _FormSection(
      title: 'Category',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ChoiceChip(
              label: 'None',
              isSelected: selectedCategoryId == null,
              onTap: () => onSelected(null),
            ),
            ...categories.map((category) {
              final isSelected = selectedCategoryId == category.id;
              return GestureDetector(
                onTap: () => onSelected(category.id),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? category.color
                        : Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        category.icon,
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        category.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class PrioritySelector extends StatelessWidget {
  final String selectedPriority;
  final ValueChanged<String> onSelected;

  const PrioritySelector({
    super.key,
    required this.selectedPriority,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _FormSection(
      title: 'Priority',
      child: Row(
        children: [
          _PriorityChoice(
            value: 'low',
            label: 'Low',
            color: AppColors.done,
            selectedPriority: selectedPriority,
            onSelected: onSelected,
          ),
          const SizedBox(width: 8),
          _PriorityChoice(
            value: 'medium',
            label: 'Medium',
            color: AppColors.pending,
            selectedPriority: selectedPriority,
            onSelected: onSelected,
          ),
          const SizedBox(width: 8),
          _PriorityChoice(
            value: 'high',
            label: 'High',
            color: AppColors.overdue,
            selectedPriority: selectedPriority,
            onSelected: onSelected,
          ),
        ],
      ),
    );
  }
}

class RecurrenceSelector extends StatelessWidget {
  final String selectedRecurrence;
  final ValueChanged<String> onSelected;

  const RecurrenceSelector({
    super.key,
    required this.selectedRecurrence,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _FormSection(
      title: 'Repeats',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _RecurrenceChoice(
              value: 'none',
              label: 'Never',
              selectedRecurrence: selectedRecurrence,
              onSelected: onSelected,
            ),
            const SizedBox(width: 8),
            _RecurrenceChoice(
              value: 'daily',
              label: 'Daily',
              selectedRecurrence: selectedRecurrence,
              onSelected: onSelected,
            ),
            const SizedBox(width: 8),
            _RecurrenceChoice(
              value: 'weekly',
              label: 'Weekly',
              selectedRecurrence: selectedRecurrence,
              onSelected: onSelected,
            ),
            const SizedBox(width: 8),
            _RecurrenceChoice(
              value: 'monthly',
              label: 'Monthly',
              selectedRecurrence: selectedRecurrence,
              onSelected: onSelected,
            ),
          ],
        ),
      ),
    );
  }
}

class MemberSelector extends StatelessWidget {
  final List<Member> members;
  final int? selectedMemberId;
  final ValueChanged<int?> onSelected;

  const MemberSelector({
    super.key,
    required this.members,
    required this.selectedMemberId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _FormSection(
      title: 'Assign to',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ChoiceChip(
              label: 'Unassigned',
              isSelected: selectedMemberId == null,
              onTap: () => onSelected(null),
            ),
            ...members.map((member) {
              final isSelected = selectedMemberId == member.id;
              return GestureDetector(
                onTap: () => onSelected(member.id),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MemberAvatar(
                        member: member,
                        size: 28,
                        showBorder: isSelected,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        member.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class DueDateSelector extends StatelessWidget {
  final DateTime? selectedDueDate;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const DueDateSelector({
    super.key,
    required this.selectedDueDate,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return _FormSection(
      title: 'Due date',
      child: GestureDetector(
        onTap: onPick,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  selectedDueDate == null
                      ? 'No due date'
                      : DateFormat('EEEE, MMM d, yyyy')
                          .format(selectedDueDate!),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              if (selectedDueDate != null)
                GestureDetector(
                  onTap: onClear,
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _FormSection({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
        ),
      ),
    );
  }
}

class _PriorityChoice extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final String selectedPriority;
  final ValueChanged<String> onSelected;

  const _PriorityChoice({
    required this.value,
    required this.label,
    required this.color,
    required this.selectedPriority,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedPriority == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelected(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color
                : Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? null
                : Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isSelected ? Colors.white.withValues(alpha: 0.8) : color,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecurrenceChoice extends StatelessWidget {
  final String value;
  final String label;
  final String selectedRecurrence;
  final ValueChanged<String> onSelected;

  const _RecurrenceChoice({
    required this.value,
    required this.label,
    required this.selectedRecurrence,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedRecurrence == value;
    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}
