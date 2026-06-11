import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/member_avatar.dart';
import '../../data/models/chore.dart';
import '../../data/models/member.dart';
import '../../data/models/chore_category.dart';
import '../../domain/chore_service.dart';
import '../../domain/member_service.dart';
import '../../domain/category_service.dart';

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
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ChoreService _choreService = ChoreService();
  final MemberService _memberService = MemberService();
  final CategoryService _categoryService = CategoryService();

  List<Member> _members = [];
  List<ChoreCategory> _categories = [];
  int? _selectedMemberId;
  DateTime? _selectedDueDate;
  int? _selectedCategoryId;
  String _selectedPriority = 'medium';
  String _selectedRecurrence = 'none';
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.chore != null;
    if (_isEditMode) {
      _titleController.text = widget.chore!.title;
      _descriptionController.text = widget.chore!.description ?? '';
      _selectedMemberId = widget.chore!.assignedMemberId;
      _selectedDueDate = widget.chore!.dueDate;
      _selectedCategoryId = widget.chore!.categoryId;
      _selectedPriority = widget.chore!.priority;
      _selectedRecurrence = widget.chore!.recurrence;
    } else {
      // Pre-fill from template if provided
      if (widget.prefilledTitle != null) {
        _titleController.text = widget.prefilledTitle!;
      }
      if (widget.prefilledCategoryId != null) {
        _selectedCategoryId = widget.prefilledCategoryId;
      }
      if (widget.prefilledMemberId != null) {
        _selectedMemberId = widget.prefilledMemberId;
      }
    }
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final members = await _memberService.getAllMembers();
    final categories = await _categoryService.getAll();
    if (mounted) {
      setState(() {
        _members = members;
        _categories = categories;
      });
    }
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentDueDate = _selectedDueDate;
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
    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
  }

  Future<void> _saveChore() async {
    if (!_formKey.currentState!.validate()) return;

    final chore = Chore(
      id: widget.chore?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      assignedMemberId: _selectedMemberId,
      dueDate: _selectedDueDate,
      isCompleted: widget.chore?.isCompleted ?? false,
      createdAt: widget.chore?.createdAt ?? DateTime.now(),
      categoryId: _selectedCategoryId,
      priority: _selectedPriority,
      recurrence: _selectedRecurrence,
    );

    if (_isEditMode) {
      await _choreService.updateChore(chore);
    } else {
      await _choreService.addChore(chore);
    }

    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _deleteChore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete this chore?',
            style: Theme.of(context).textTheme.titleMedium),
        content: Text('This action cannot be undone.',
            style: Theme.of(context).textTheme.bodyMedium),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _choreService.deleteChore(widget.chore!.id!);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Chore' : 'New Chore'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field
              TextFormField(
                controller: _titleController,
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

              // Description field
              TextFormField(
                controller: _descriptionController,
                maxLength: 200,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Add a note (optional)',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 32),

              // Category section
              Text(
                'Category',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // None chip
                    GestureDetector(
                      onTap: () => setState(() => _selectedCategoryId = null),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: _selectedCategoryId == null
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerLow,
                          borderRadius: BorderRadius.circular(20),
                          border: _selectedCategoryId == null
                              ? Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 1.5)
                              : Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                                  width: 1),
                        ),
                        child: Text(
                          'None',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: _selectedCategoryId == null
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                    fontWeight: _selectedCategoryId == null
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                        ),
                      ),
                    ),
                    // Category chips
                    ..._categories.map((cat) {
                      final isSelected = _selectedCategoryId == cat.id;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCategoryId = cat.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cat.color
                                : Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                            border: isSelected
                                ? null
                                : Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
                                    width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                cat.icon,
                                size: 16,
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                cat.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: isSelected
                                          ? Colors.white
                                          : Theme.of(context)
                                              .colorScheme
                                              .primary,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Priority section
              Text(
                'Priority',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildPriorityChip('low', 'Low', AppColors.done),
                  const SizedBox(width: 8),
                  _buildPriorityChip('medium', 'Medium', AppColors.pending),
                  const SizedBox(width: 8),
                  _buildPriorityChip('high', 'High', AppColors.overdue),
                ],
              ),
              const SizedBox(height: 32),

              // Recurrence section
              Text(
                'Repeats',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildRecurrenceChip('none', 'Never'),
                    const SizedBox(width: 8),
                    _buildRecurrenceChip('daily', 'Daily'),
                    const SizedBox(width: 8),
                    _buildRecurrenceChip('weekly', 'Weekly'),
                    const SizedBox(width: 8),
                    _buildRecurrenceChip('monthly', 'Monthly'),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Assign to section
              Text(
                'Assign to',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Unassigned chip
                    GestureDetector(
                      onTap: () => setState(() => _selectedMemberId = null),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: _selectedMemberId == null
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerLow,
                          borderRadius: BorderRadius.circular(20),
                          border: _selectedMemberId == null
                              ? Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 1.5)
                              : Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                                  width: 1),
                        ),
                        child: Text(
                          'Unassigned',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: _selectedMemberId == null
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                    fontWeight: _selectedMemberId == null
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                        ),
                      ),
                    ),
                    // Member chips
                    ..._members.map((member) {
                      final isSelected = _selectedMemberId == member.id;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedMemberId = member.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerLow,
                            borderRadius: BorderRadius.circular(20),
                            border: isSelected
                                ? Border.all(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 1.5)
                                : Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
                                    width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              MemberAvatar(
                                  member: member,
                                  size: 28,
                                  showBorder: isSelected),
                              const SizedBox(width: 8),
                              Text(
                                member.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: isSelected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Due date section
              Text(
                'Due date',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickDueDate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 18,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedDueDate != null
                              ? DateFormat('EEEE, MMM d, yyyy')
                                  .format(_selectedDueDate!)
                              : 'No due date',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      if (_selectedDueDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _selectedDueDate = null),
                          child: Icon(Icons.close,
                              size: 18,
                              color: Theme.of(context).colorScheme.outline),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveChore,
                  child: const Text('Save Chore'),
                ),
              ),

              // Delete option (edit mode only)
              if (_isEditMode) ...[
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _deleteChore,
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
  }

  Widget _buildPriorityChip(String value, String label, Color color) {
    final isSelected = _selectedPriority == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPriority = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color
                : Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? null
                : Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isSelected ? Colors.white.withValues(alpha: 0.8) : color,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecurrenceChip(String value, String label) {
    final isSelected = _selectedRecurrence == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedRecurrence = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}
