import 'package:flutter/material.dart';
import '../../data/models/chore_category.dart';
import '../../data/chore_templates.dart';
import '../../domain/category_service.dart';
import 'add_edit_chore_screen.dart';
import 'chore_template_category_screen.dart';

class ChoreTemplateScreen extends StatefulWidget {
  final int? prefilledMemberId;

  const ChoreTemplateScreen({super.key, this.prefilledMemberId});

  @override
  State<ChoreTemplateScreen> createState() => _ChoreTemplateScreenState();
}

class _ChoreTemplateScreenState extends State<ChoreTemplateScreen> {
  final CategoryService _categoryService = CategoryService();
  final TextEditingController _searchController = TextEditingController();

  List<ChoreCategory> _categories = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchController.addListener(() {
      setState(
          () => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = await _categoryService.getAll();
    if (mounted) {
      setState(() => _categories = categories);
    }
  }

  List<_SearchResult> get _searchResults {
    if (_searchQuery.isEmpty) return [];

    final results = <_SearchResult>[];
    for (final entry in ChoreTemplates.byCategory.entries) {
      final categoryName = entry.key;
      final category = _categories.cast<ChoreCategory?>().firstWhere(
            (c) => c!.name == categoryName,
            orElse: () => null,
          );

      for (final template in entry.value) {
        if (template.toLowerCase().contains(_searchQuery) ||
            categoryName.toLowerCase().contains(_searchQuery)) {
          results.add(_SearchResult(
            title: template,
            categoryName: categoryName,
            category: category,
          ));
        }
      }
    }
    return results;
  }

  Future<void> _openAddChore({String? title, int? categoryId}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditChoreScreen(
          prefilledTitle: title,
          prefilledCategoryId: categoryId,
          prefilledMemberId: widget.prefilledMemberId,
        ),
      ),
    );
    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _openCategory(ChoreCategory category) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ChoreTemplateCategoryScreen(
          category: category,
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
    final isSearching = _searchQuery.isNotEmpty;
    final searchResults = _searchResults;

    return Scaffold(
      appBar: AppBar(
        title: const Text('What needs doing?'),
      ),
      body: Column(
        children: [
          // Search field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search chores...',
                prefixIcon: Icon(Icons.search,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close,
                            color: Theme.of(context).colorScheme.outline),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: isSearching
                ? _buildSearchResults(searchResults)
                : _buildCategoryGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<_SearchResult> results) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 24;

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off,
                size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              'No matching chores',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final result = results[index];
        return GestureDetector(
          onTap: () => _openAddChore(
            title: result.title,
            categoryId: result.category?.id,
          ),
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
                if (result.category != null) ...[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: result.category!.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      result.category!.icon,
                      size: 16,
                      color: result.category!.color,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        result.categoryName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.add_circle_outline,
                    color: Theme.of(context).colorScheme.primary, size: 22),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryGrid() {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 24;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final cat = _categories[index];
                final choreCount =
                    ChoreTemplates.byCategory[cat.name]?.length ?? 0;

                return GestureDetector(
                  onTap: () => _openCategory(cat),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: cat.color.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(cat.icon, size: 28, color: cat.color),
                        const SizedBox(height: 8),
                        Text(
                          cat.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$choreCount chores',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: _categories.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => _openAddChore(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.edit_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Custom chore',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Type your own',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.outline),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: Theme.of(context).colorScheme.outline, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: bottomPadding)),
      ],
    );
  }
}

class _SearchResult {
  final String title;
  final String categoryName;
  final ChoreCategory? category;

  _SearchResult({
    required this.title,
    required this.categoryName,
    this.category,
  });
}
