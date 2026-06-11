import 'package:flutter/material.dart';

import '../../data/models/chore.dart';
import '../../data/models/chore_category.dart';
import '../../data/models/member.dart';
import '../../domain/category_service.dart';
import '../../domain/chore_service.dart';
import '../../domain/member_service.dart';

class ChoreFormController extends ChangeNotifier {
  final ChoreService _choreService;
  final MemberService _memberService;
  final CategoryService _categoryService;
  final Chore? originalChore;

  ChoreFormController({
    this.originalChore,
    String? prefilledTitle,
    int? prefilledCategoryId,
    int? prefilledMemberId,
    ChoreService? choreService,
    MemberService? memberService,
    CategoryService? categoryService,
  })  : _choreService = choreService ?? ChoreService(),
        _memberService = memberService ?? MemberService(),
        _categoryService = categoryService ?? CategoryService(),
        titleController = TextEditingController(
          text: originalChore?.title ?? prefilledTitle ?? '',
        ),
        descriptionController = TextEditingController(
          text: originalChore?.description ?? '',
        ),
        selectedMemberId = originalChore?.assignedMemberId ?? prefilledMemberId,
        selectedDueDate = originalChore?.dueDate,
        selectedCategoryId = originalChore?.categoryId ?? prefilledCategoryId,
        selectedPriority = originalChore?.priority ?? 'medium',
        selectedRecurrence = originalChore?.recurrence ?? 'none';

  final TextEditingController titleController;
  final TextEditingController descriptionController;

  List<Member> members = [];
  List<ChoreCategory> categories = [];
  int? selectedMemberId;
  DateTime? selectedDueDate;
  int? selectedCategoryId;
  String selectedPriority;
  String selectedRecurrence;
  bool isLoadingOptions = true;
  bool isSaving = false;
  bool _isDisposed = false;

  bool get isEditMode => originalChore != null;

  Future<void> loadOptions() async {
    final loadedMembers = await _memberService.getAllMembers();
    final loadedCategories = await _categoryService.getAll();
    if (_isDisposed) return;
    members = loadedMembers;
    categories = loadedCategories;
    isLoadingOptions = false;
    notifyListeners();
  }

  void selectMember(int? memberId) {
    if (selectedMemberId == memberId) return;
    selectedMemberId = memberId;
    _notify();
  }

  void selectCategory(int? categoryId) {
    if (selectedCategoryId == categoryId) return;
    selectedCategoryId = categoryId;
    _notify();
  }

  void selectPriority(String priority) {
    if (selectedPriority == priority) return;
    selectedPriority = priority;
    _notify();
  }

  void selectRecurrence(String recurrence) {
    if (selectedRecurrence == recurrence) return;
    selectedRecurrence = recurrence;
    _notify();
  }

  void selectDueDate(DateTime? dueDate) {
    if (selectedDueDate == dueDate) return;
    selectedDueDate = dueDate;
    _notify();
  }

  Chore buildChore() {
    final description = descriptionController.text.trim();
    return Chore(
      id: originalChore?.id,
      title: titleController.text.trim(),
      description: description.isEmpty ? null : description,
      assignedMemberId: selectedMemberId,
      dueDate: selectedDueDate,
      isCompleted: originalChore?.isCompleted ?? false,
      createdAt: originalChore?.createdAt ?? DateTime.now(),
      categoryId: selectedCategoryId,
      priority: selectedPriority,
      recurrence: selectedRecurrence,
      householdId: originalChore?.householdId,
    );
  }

  Future<void> save() async {
    if (isSaving) return;
    isSaving = true;
    _notify();
    try {
      final chore = buildChore();
      if (isEditMode) {
        await _choreService.updateChore(chore);
      } else {
        await _choreService.addChore(chore);
      }
    } finally {
      isSaving = false;
      _notify();
    }
  }

  Future<void> delete() async {
    final id = originalChore?.id;
    if (id != null) await _choreService.deleteChore(id);
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
