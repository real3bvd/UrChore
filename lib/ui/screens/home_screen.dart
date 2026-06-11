import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/chore.dart';
import '../../domain/auth_service.dart';
import '../controllers/home_controller.dart';
import '../widgets/app_notification.dart';
import '../widgets/home/home_content.dart';
import '../widgets/home/home_header.dart';
import 'add_edit_chore_screen.dart';
import 'chore_template_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToChores;

  const HomeScreen({super.key, this.onNavigateToChores});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HomeController()..loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleChore(Chore chore) async {
    final result = await _controller.toggleChore(chore);
    if (!mounted || !result.completed) return;

    final message = result.nextDueDate == null
        ? '${chore.title} completed. Nice work!'
        : '${chore.title} completed. Next: '
            '${DateFormat('EEE, MMM d').format(result.nextDueDate!)}.';
    showAppNotification(
      context,
      message,
      actionLabel: 'Undo',
      onAction: () => _controller.undoCompletion(chore, result),
    );
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
        builder: (_) => AddEditChoreScreen(
          prefilledMemberId: AuthService.instance.currentUser?.memberId,
        ),
      ),
    );
    if (result == true) await _controller.loadData();
  }

  Future<void> _openTemplates() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ChoreTemplateScreen(
          prefilledMemberId: AuthService.instance.currentUser?.memberId,
        ),
      ),
    );
    if (result == true) await _controller.loadData();
  }

  Future<void> _claimChore(Chore chore) async {
    await _controller.claimChore(chore);
    if (!mounted) return;
    showAppNotification(
      context,
      '${chore.title} is now assigned to you.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final userName =
        AuthService.instance.currentUser?.displayName.trim() ?? 'there';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _controller.loadData,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 104),
                children: [
                  HomeGreetingHeader(
                    greeting: 'Hey $userName',
                    date: DateFormat('EEEE, MMM d').format(now),
                  ),
                  const SizedBox(height: 24),
                  WeeklyCalendarStrip(
                    weekStart: _controller.weekStart,
                    choreDays: _controller.assignedChoreDays,
                    today: now,
                  ),
                  const SizedBox(height: 28),
                  if (_controller.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 72),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_controller.assignedChores.isEmpty)
                    EmptyHomeContent(
                      unassignedChores: _controller.unassignedChores,
                      weeklyHouseholdChores: _controller.weeklyHouseholdChores,
                      findCategory: _controller.findCategory,
                      onAddChore: _openAddChore,
                      onBrowseTemplates: _openTemplates,
                      onClaim: _claimChore,
                      onOpen: _openEditChore,
                    )
                  else
                    AssignedChoreSection(
                      chores: _controller.assignedChores,
                      findMember: _controller.findMember,
                      findCategory: _controller.findCategory,
                      onToggle: _toggleChore,
                      onOpen: _openEditChore,
                      onSeeAll: widget.onNavigateToChores,
                    ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add chore',
        onPressed: _openAddChore,
        child: const Icon(Icons.add),
      ),
    );
  }
}
