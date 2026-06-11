import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/chore.dart';
import '../../data/models/member.dart';
import '../../data/models/chore_category.dart';
import '../theme/app_theme.dart';

class ChoreCard extends StatelessWidget {
  final Chore chore;
  final Member? assignedMember;
  final ChoreCategory? category;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const ChoreCard({
    super.key,
    required this.chore,
    this.assignedMember,
    this.category,
    required this.onToggle,
    required this.onTap,
  });

  Color _memberColor(BuildContext context) {
    if (assignedMember == null) return Theme.of(context).colorScheme.outline;
    return Color(int.parse('FF${assignedMember!.colorHex}', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = chore.isCompleted;
    final contentOpacity = isCompleted ? 0.5 : 1.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant, width: 1),
        ),
        child: Opacity(
          opacity: contentOpacity,
          child: Row(
            children: [
              // Priority indicator bar
              Container(
                width: 4,
                height: 32,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  color: chore.priorityColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Main content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 16, 16),
                  child: Row(
                    children: [
                      // Checkbox circle
                      GestureDetector(
                        onTap: onToggle,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? AppColors.done
                                : Colors.transparent,
                            border: Border.all(
                              color: isCompleted
                                  ? AppColors.done
                                  : Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                              width: 2,
                            ),
                          ),
                          child: isCompleted
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chore.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    decoration: isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (assignedMember != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _memberColor(context)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      assignedMember!.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: _memberColor(context),
                                          ),
                                    ),
                                  ),
                                if (category != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: category!.color
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          category!.icon,
                                          size: 12,
                                          color: category!.color,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          category!.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                  color: category!.color),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (chore.dueDate != null)
                                  Text(
                                    DateFormat('MMM d').format(chore.dueDate!),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: chore.isOverdue
                                              ? AppColors.overdue
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .outline,
                                        ),
                                  ),
                                if (chore.recurrence != 'none')
                                  Icon(
                                    Icons.repeat,
                                    size: 12,
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Chevron
                      Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).colorScheme.outline,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
