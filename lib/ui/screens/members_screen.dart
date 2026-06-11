import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/hedgehog_painter.dart';
import '../widgets/member_avatar.dart';
import '../widgets/app_notification.dart';
import '../../data/models/member.dart';
import '../../domain/auth_service.dart';
import '../controllers/members_controller.dart';

class MembersScreen extends StatefulWidget {
  final MembersController? controller;

  const MembersScreen({super.key, this.controller});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  late final MembersController _controller;
  late final bool _ownsController;

  static const List<String> _colorOptions = [
    '5C8B6E',
    'E07B54',
    '5B8DB8',
    'C4784E',
    '8B6BAE',
    'C2A24C',
  ];

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? MembersController();
    _controller.loadMembers();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  Future<void> _showAddMemberSheet() async {
    final nameController = TextEditingController();
    String selectedColor = _colorOptions[0];
    bool isSaving = false;
    final formKey = GlobalKey<FormState>();

    final didAdd = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Member',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: nameController,
                      maxLength: 30,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        counterText: '',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Pick a color',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _colorOptions.map((hex) {
                        final color = Color(int.parse('FF$hex', radix: 16));
                        final isSelected = selectedColor == hex;
                        return GestureDetector(
                          onTap: () {
                            setSheetState(() => selectedColor = hex);
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              border: isSelected
                                  ? Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      width: 3)
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 20)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;

                                setSheetState(() => isSaving = true);
                                final member = Member(
                                  name: nameController.text.trim(),
                                  colorHex: selectedColor,
                                  createdAt: DateTime.now(),
                                );

                                try {
                                  await _controller.addMember(member);
                                  if (context.mounted) {
                                    Navigator.pop(context, true);
                                  }
                                } catch (error) {
                                  if (!context.mounted) return;
                                  setSheetState(() => isSaving = false);
                                  showAppNotification(
                                    context,
                                    'Could not add member: $error',
                                  );
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Add'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (didAdd == true) return;
  }

  Future<void> _deleteMember(Member member) async {
    final activeCount = await _controller.getActiveChoreCount(member.id!);
    if (!mounted) return;

    String body = 'Are you sure you want to remove ${member.name}?';
    if (activeCount > 0) {
      body +=
          '\n\nThis member has $activeCount active chore${activeCount == 1 ? '' : 's'}. They will become unassigned.';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remove member?',
            style: Theme.of(context).textTheme.titleMedium),
        content: Text(body, style: Theme.of(context).textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.overdue,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _controller.deleteMember(member.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Members')),
        body: _controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : _controller.members.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const HedgehogWidget(
                            size: 60, activity: HedgehogActivity.waving),
                        const SizedBox(height: 16),
                        Text(
                          'No members yet. Add your household.',
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
                    itemCount: _controller.members.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final member = _controller.members[index];
                      final displayMember =
                          _controller.memberForDisplay(member);
                      final choreCount =
                          _controller.choreCounts[member.id] ?? 0;
                      final isCurrentUser = member.id ==
                          AuthService.instance.currentUser?.memberId;
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color:
                                  Theme.of(context).colorScheme.outlineVariant,
                              width: 1),
                        ),
                        child: Row(
                          children: [
                            MemberAvatar(member: displayMember, size: 44),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayMember.name,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isCurrentUser
                                        ? '${AuthService.instance.currentUser?.role == 'owner' ? 'Owner' : 'Member'} · $choreCount chore${choreCount == 1 ? '' : 's'} assigned'
                                        : '$choreCount chore${choreCount == 1 ? '' : 's'} assigned',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            if (!isCurrentUser)
                              IconButton(
                                onPressed: () => _deleteMember(member),
                                icon: Icon(Icons.close,
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                    size: 20),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddMemberSheet,
          child: const Icon(Icons.person_add),
        ),
      ),
    );
  }
}
