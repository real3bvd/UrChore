import 'package:flutter/material.dart';
import '../widgets/chore_card.dart';
import '../widgets/hedgehog_painter.dart';
import '../../data/models/chore.dart';
import '../../data/models/member.dart';
import '../../data/models/chore_category.dart';
import '../../domain/chore_service.dart';
import '../../domain/member_service.dart';
import '../../domain/category_service.dart';
import 'add_edit_chore_screen.dart';
import 'chore_template_screen.dart';

class ChoresScreen extends StatefulWidget {
  const ChoresScreen({super.key});

  @override
  State<ChoresScreen> createState() => ChoresScreenState();
}

class ChoresScreenState extends State<ChoresScreen> {
  final ChoreService _choreService = ChoreService();
  final MemberService _memberService = MemberService();
  final CategoryService _categoryService = CategoryService();

  List<Chore> _allChores = [];
  List<Member> _members = [];
  Map<int, ChoreCategory> _categoryMap = {};
  int _selectedFilter = 0; // 0=All, 1=Pending, 2=Done

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final chores = await _choreService.getAllChores();
    final members = await _memberService.getAllMembers();
    final categories = await _categoryService.getAll();

    final categoryMap = <int, ChoreCategory>{};
    for (final cat in categories) {
      if (cat.id != null) categoryMap[cat.id!] = cat;
    }

    if (mounted) {
      setState(() {
        _allChores = chores;
        _members = members;
        _categoryMap = categoryMap;
      });
    }
  }

  List<Chore> get _filteredChores {
    switch (_selectedFilter) {
      case 1:
        return _allChores.where((c) => !c.isCompleted).toList();
      case 2:
        return _allChores.where((c) => c.isCompleted).toList();
      default:
        return _allChores;
    }
  }

  Member? _findMember(int? memberId) {
    if (memberId == null) return null;
    try {
      return _members.firstWhere((m) => m.id == memberId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _toggleChore(Chore chore) async {
    await _choreService.toggleComplete(chore);
    loadData();
  }

  Future<void> _openEditChore(Chore chore) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditChoreScreen(chore: chore),
      ),
    );
    if (result == true) loadData();
  }

  Future<void> _openAddChore() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const ChoreTemplateScreen(),
      ),
    );
    if (result == true) loadData();
  }

  String get _emptyMessage {
    switch (_selectedFilter) {
      case 1:
        return 'No pending chores';
      case 2:
        return 'No completed chores';
      default:
        return 'No chores yet';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredChores = _filteredChores;
    final filterLabels = ['All', 'Pending', 'Done'];

    return Scaffold(
      appBar: AppBar(title: const Text('Chores')),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: List.generate(3, (index) {
                final isActive = _selectedFilter == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        filterLabels[index],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isActive
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Chore list or empty state
          Expanded(
            child: filteredChores.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const HedgehogWidget(
                            size: 60, activity: HedgehogActivity.cleaning),
                        const SizedBox(height: 16),
                        Text(
                          _emptyMessage,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: Theme.of(context).colorScheme.outline),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredChores.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final chore = filteredChores[index];
                      return ChoreCard(
                        chore: chore,
                        assignedMember: _findMember(chore.assignedMemberId),
                        category: chore.categoryId != null
                            ? _categoryMap[chore.categoryId]
                            : null,
                        onToggle: () => _toggleChore(chore),
                        onTap: () => _openEditChore(chore),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddChore,
        child: const Icon(Icons.add),
      ),
    );
  }
}
