import 'package:flutter/material.dart';
import '../../ui/theme/app_theme.dart';

class Chore {
  final int? id;
  final String title;
  final String? description;
  final int? assignedMemberId;
  final DateTime? dueDate;
  final bool isCompleted;
  final DateTime createdAt;
  final int? categoryId;
  final String priority;
  final String recurrence;
  final int? householdId;

  const Chore({
    this.id,
    required this.title,
    this.description,
    this.assignedMemberId,
    this.dueDate,
    required this.isCompleted,
    required this.createdAt,
    this.categoryId,
    this.priority = 'medium',
    this.recurrence = 'none',
    this.householdId,
  });

  bool get isOverdue =>
      dueDate != null && !isCompleted && dueDate!.isBefore(DateTime.now());

  bool occursOn(DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    final source = dueDate ?? createdAt;
    final start = DateTime(source.year, source.month, source.day);

    if (target.isBefore(start)) return false;

    switch (recurrence) {
      case 'daily':
        return true;
      case 'weekly':
        return target.difference(start).inDays % 7 == 0;
      case 'monthly':
        final monthOffset =
            (target.year - start.year) * 12 + target.month - start.month;
        final occurrence = DateTime(
          start.year,
          start.month + monthOffset,
          start.day,
        );
        return _sameDay(target, occurrence);
      default:
        return dueDate != null && _sameDay(target, start);
    }
  }

  static bool _sameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  Color get priorityColor {
    switch (priority) {
      case 'high':
        return AppColors.overdue;
      case 'medium':
        return AppColors.pending;
      case 'low':
        return AppColors.done;
      default:
        return AppColors.textLight;
    }
  }

  Chore copyWith({
    int? id,
    String? title,
    String? description,
    int? assignedMemberId,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? createdAt,
    int? categoryId,
    String? priority,
    String? recurrence,
    int? householdId,
    bool clearAssignedMember = false,
    bool clearDueDate = false,
    bool clearCategory = false,
  }) {
    return Chore(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedMemberId: clearAssignedMember
          ? null
          : (assignedMemberId ?? this.assignedMemberId),
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      priority: priority ?? this.priority,
      recurrence: recurrence ?? this.recurrence,
      householdId: householdId ?? this.householdId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'assigned_member_id': assignedMemberId,
      'due_date': dueDate?.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'category_id': categoryId,
      'priority': priority,
      'recurrence': recurrence,
      'household_id': householdId,
    };
  }

  factory Chore.fromMap(Map<String, dynamic> map) {
    return Chore(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      assignedMemberId: map['assigned_member_id'] as int?,
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      isCompleted: (map['is_completed'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      categoryId: map['category_id'] as int?,
      priority: (map['priority'] as String?) ?? 'medium',
      recurrence: (map['recurrence'] as String?) ?? 'none',
      householdId: map['household_id'] as int?,
    );
  }
}
