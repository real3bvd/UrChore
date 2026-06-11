import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../hedgehog_painter.dart';

class HomeGreetingHeader extends StatelessWidget {
  final String greeting;
  final String date;

  const HomeGreetingHeader({
    super.key,
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

class WeeklyCalendarStrip extends StatelessWidget {
  final DateTime weekStart;
  final Set<int> choreDays;
  final DateTime today;

  const WeeklyCalendarStrip({
    super.key,
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

  static bool _sameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}
