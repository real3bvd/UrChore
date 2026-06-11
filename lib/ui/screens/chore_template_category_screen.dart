import 'package:flutter/material.dart';
import '../../data/models/chore_category.dart';
import '../../data/chore_templates.dart';
import 'add_edit_chore_screen.dart';

class ChoreTemplateCategoryScreen extends StatefulWidget {
  final ChoreCategory category;
  final int? prefilledMemberId;

  const ChoreTemplateCategoryScreen({
    super.key,
    required this.category,
    this.prefilledMemberId,
  });

  @override
  State<ChoreTemplateCategoryScreen> createState() =>
      _ChoreTemplateCategoryScreenState();
}

class _ChoreTemplateCategoryScreenState
    extends State<ChoreTemplateCategoryScreen> {
  List<String> get _templates =>
      ChoreTemplates.byCategory[widget.category.name] ?? [];

  Future<void> _openAddChore(String title) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditChoreScreen(
          prefilledTitle: title,
          prefilledCategoryId: widget.category.id,
          prefilledMemberId: widget.prefilledMemberId,
        ),
      ),
    );
    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    final templates = _templates;

    return Scaffold(
      appBar: AppBar(
        title: Text(cat.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cat.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(cat.icon, size: 48, color: cat.color),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${templates.length} chore templates',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Template list
          ...templates.map((template) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _openAddChore(template),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        width: 1),
                  ),
                  child: Row(
                    children: [
                      // Small category circle
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: cat.color.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(cat.icon, size: 16, color: cat.color),
                      ),
                      const SizedBox(width: 12),
                      // Chore title
                      Expanded(
                        child: Text(
                          template,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      // Add icon
                      Icon(Icons.add_circle_outline,
                          color: Theme.of(context).colorScheme.primary,
                          size: 22),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
