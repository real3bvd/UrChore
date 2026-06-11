import 'package:flutter/material.dart';

import '../../data/models/chore.dart';
import '../controllers/chores_controller.dart';
import '../widgets/app_notification.dart';
import '../widgets/chore_card.dart';
import '../widgets/hedgehog_painter.dart';
import 'add_edit_chore_screen.dart';
import 'chore_template_screen.dart';

class ChoresScreen extends StatefulWidget {
  final ChoresController? controller;

  const ChoresScreen({super.key, this.controller});

  @override
  State<ChoresScreen> createState() => _ChoresScreenState();
}

class _ChoresScreenState extends State<ChoresScreen> {
  late final ChoresController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? ChoresController();
    _controller.loadData();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleChore(Chore chore) async {
    final result = await _controller.toggleChore(chore);
    if (!mounted) return;

    if (!result.completed) {
      showAppNotification(
        context,
        '${chore.title} moved back to Pending.',
      );
      return;
    }

    final message = result.nextDueDate == null
        ? '${chore.title} completed.'
        : '${chore.title} completed. Next: '
            '${_formatDate(result.nextDueDate!)}.';
    showAppNotification(
      context,
      message,
      actionLabel: 'Undo',
      onAction: () => _controller.undoCompletion(chore, result),
    );
  }

  String _formatDate(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[date.weekday - 1]}, '
        '${months[date.month - 1]} ${date.day}';
  }

  Future<void> _openEditChore(Chore chore) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditChoreScreen(chore: chore),
      ),
    );
    if (result == true) await _controller.loadData();
  }

  Future<void> _openAddChore() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const ChoreTemplateScreen(),
      ),
    );
    if (result == true) await _controller.loadData();
  }

  @override
  Widget build(BuildContext context) {
    const filterLabels = ['All', 'Pending', 'Done'];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final filteredChores = _controller.filteredChores;
        return Scaffold(
          appBar: AppBar(title: const Text('Chores')),
          body: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: List.generate(3, (index) {
                    final isActive = _controller.selectedFilter == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _controller.selectFilter(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            filterLabels[index],
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
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
              Expanded(
                child: _controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredChores.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const HedgehogWidget(
                                  size: 60,
                                  activity: HedgehogActivity.cleaning,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _controller.emptyMessage,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline,
                                      ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredChores.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final chore = filteredChores[index];
                              return ChoreCard(
                                chore: chore,
                                assignedMember: _controller
                                    .findMember(chore.assignedMemberId),
                                category:
                                    _controller.findCategory(chore.categoryId),
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
      },
    );
  }
}
