import 'package:flutter/material.dart';

import '../../data/models/chore.dart';
import '../controllers/chore_form_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/chore_form/chore_form_sections.dart';

class AddEditChoreScreen extends StatefulWidget {
  final Chore? chore;
  final String? prefilledTitle;
  final int? prefilledCategoryId;
  final int? prefilledMemberId;

  const AddEditChoreScreen({
    super.key,
    this.chore,
    this.prefilledTitle,
    this.prefilledCategoryId,
    this.prefilledMemberId,
  });

  @override
  State<AddEditChoreScreen> createState() => _AddEditChoreScreenState();
}

class _AddEditChoreScreenState extends State<AddEditChoreScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ChoreFormController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ChoreFormController(
      originalChore: widget.chore,
      prefilledTitle: widget.prefilledTitle,
      prefilledCategoryId: widget.prefilledCategoryId,
      prefilledMemberId: widget.prefilledMemberId,
    )..loadOptions();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentDueDate = _controller.selectedDueDate;
    final initialDate =
        currentDueDate != null && !currentDueDate.isBefore(today)
            ? currentDueDate
            : today;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime(today.year + 2, today.month, today.day),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) _controller.selectDueDate(picked);
  }

  Future<void> _saveChore() async {
    if (!_formKey.currentState!.validate()) return;
    await _controller.save();
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _deleteChore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete this chore?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        content: Text(
          'This action cannot be undone.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.overdue,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _controller.delete();
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_controller.isEditMode ? 'Edit Chore' : 'New Chore'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _controller.titleController,
                    maxLength: 60,
                    decoration: const InputDecoration(
                      labelText: 'What needs to be done?',
                      counterText: '',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _controller.descriptionController,
                    maxLength: 200,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Add a note (optional)',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 32),
                  CategorySelector(
                    categories: _controller.categories,
                    selectedCategoryId: _controller.selectedCategoryId,
                    onSelected: _controller.selectCategory,
                  ),
                  const SizedBox(height: 32),
                  PrioritySelector(
                    selectedPriority: _controller.selectedPriority,
                    onSelected: _controller.selectPriority,
                  ),
                  const SizedBox(height: 32),
                  RecurrenceSelector(
                    selectedRecurrence: _controller.selectedRecurrence,
                    onSelected: _controller.selectRecurrence,
                  ),
                  const SizedBox(height: 32),
                  MemberSelector(
                    members: _controller.members,
                    selectedMemberId: _controller.selectedMemberId,
                    onSelected: _controller.selectMember,
                  ),
                  const SizedBox(height: 32),
                  DueDateSelector(
                    selectedDueDate: _controller.selectedDueDate,
                    onPick: _pickDueDate,
                    onClear: () => _controller.selectDueDate(null),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _controller.isSaving ? null : _saveChore,
                      child: _controller.isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Chore'),
                    ),
                  ),
                  if (_controller.isEditMode) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: _controller.isSaving ? null : _deleteChore,
                        child: Text(
                          'Delete this chore',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.overdue),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
