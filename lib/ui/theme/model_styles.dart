import 'package:flutter/material.dart';

import '../../data/models/chore.dart';
import '../../data/models/chore_category.dart';
import 'app_theme.dart';

extension ChoreStyle on Chore {
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
}

extension ChoreCategoryStyle on ChoreCategory {
  Color get color => Color(int.parse('FF$colorHex', radix: 16));

  IconData get icon {
    switch (iconName) {
      case 'kitchen':
        return Icons.kitchen_outlined;
      case 'bathroom':
        return Icons.bathtub_outlined;
      case 'bedroom':
        return Icons.bed_outlined;
      case 'living_room':
        return Icons.weekend_outlined;
      case 'garden':
        return Icons.yard_outlined;
      case 'laundry':
        return Icons.local_laundry_service_outlined;
      case 'garage':
        return Icons.garage_outlined;
      case 'general':
      default:
        return Icons.home_outlined;
    }
  }
}
