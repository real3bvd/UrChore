import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:urchore/data/dao/account_dao.dart';
import 'package:urchore/data/models/app_user.dart';
import 'package:urchore/data/models/chore.dart';
import 'package:urchore/data/models/household.dart';
import 'package:urchore/data/models/member.dart';
import 'package:urchore/data/web_memory_store.dart';
import 'package:urchore/domain/auth_service.dart';
import 'package:urchore/domain/chore_service.dart';
import 'package:urchore/ui/screens/avatar_picker_screen.dart';
import 'package:urchore/ui/screens/household_setup_screen.dart';
import 'package:urchore/ui/screens/home_screen.dart';
import 'package:urchore/ui/screens/members_screen.dart';
import 'package:urchore/ui/widgets/app_notification.dart';
import 'package:urchore/ui/widgets/profile_avatar.dart';

void main() {
  test('AppUser converts to and from a database map', () {
    final createdAt = DateTime(2026, 6, 10);
    final user = AppUser(
      id: 4,
      email: 'abdu3990@gmail.com',
      passwordHash: 'hash',
      displayName: 'abdu3990',
      avatarType: 'initials',
      colorHex: '5C8B6E',
      householdId: 2,
      memberId: 7,
      role: 'owner',
      createdAt: createdAt,
    );

    final restored = AppUser.fromMap(user.toMap());

    expect(restored.email, user.email);
    expect(restored.displayName, user.displayName);
    expect(restored.householdId, user.householdId);
    expect(restored.memberId, user.memberId);
    expect(restored.role, 'owner');
  });

  testWidgets('ProfileAvatar supports default and initial avatars',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              ProfileAvatar(name: 'Abdullah'),
              ProfileAvatar(
                name: 'Abdullah',
                avatarType: 'initials',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('Avatar picker keeps its save action visible on a phone',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: AvatarPickerScreen(displayName: 'Abdullah'),
      ),
    );

    final saveButton = find.text('Use this picture');
    expect(saveButton, findsOneWidget);
    expect(tester.getBottomRight(saveButton).dy, lessThan(640));

    final takePhotoButton = find.text('Take photo');
    await tester.ensureVisible(takePhotoButton);
    await tester.pumpAndSettle();

    expect(takePhotoButton, findsOneWidget);
    expect(
      tester.getBottomRight(takePhotoButton).dy,
      lessThan(tester.getTopLeft(saveButton).dy),
    );
  });

  test('Daily chores occur every day from their due date', () {
    final chore = Chore(
      title: 'Wipe counters',
      dueDate: DateTime(2026, 6, 11),
      isCompleted: false,
      createdAt: DateTime(2026, 6, 10),
      recurrence: 'daily',
    );

    expect(chore.occursOn(DateTime(2026, 6, 10)), isFalse);
    expect(chore.occursOn(DateTime(2026, 6, 11)), isTrue);
    expect(chore.occursOn(DateTime(2026, 6, 12)), isTrue);
    expect(chore.occursOn(DateTime(2026, 6, 17)), isTrue);
  });

  test('Recurring schedules calculate their next due date', () {
    final base = DateTime(2026, 6, 11);

    expect(
      ChoreService.nextRecurrenceDate('daily', base),
      DateTime(2026, 6, 12),
    );
    expect(
      ChoreService.nextRecurrenceDate('weekly', base),
      DateTime(2026, 6, 18),
    );
    expect(
      ChoreService.nextRecurrenceDate('monthly', base),
      DateTime(2026, 7, 11),
    );
    expect(ChoreService.nextRecurrenceDate('none', base), isNull);
  });

  test('Recurring completion avoids duplicates and supports undo', () async {
    WebMemoryStore.persistenceEnabled = false;
    addTearDown(() => WebMemoryStore.persistenceEnabled = true);
    final today = DateTime.now();
    final source = Chore(
      id: 1,
      title: 'Make the bed',
      assignedMemberId: 1,
      dueDate: today,
      isCompleted: false,
      createdAt: today,
      recurrence: 'daily',
      householdId: 1,
    );
    final existingNext = source.copyWith(
      id: 2,
      dueDate: today.add(const Duration(days: 1)),
      createdAt: today.add(const Duration(minutes: 1)),
    );
    AuthService.instance.currentUser = AppUser(
      id: 1,
      email: 'bb@gmail.com',
      passwordHash: 'hash',
      displayName: 'bb',
      householdId: 1,
      memberId: 1,
      createdAt: today,
    );
    WebMemoryStore.chores
      ..clear()
      ..addAll([source, existingNext]);
    addTearDown(_clearHomeData);

    final service = ChoreService();
    final result = await service.toggleComplete(source);

    expect(result.completed, isTrue);
    expect(result.createdNextChoreId, isNull);
    expect(
      WebMemoryStore.chores
          .where((chore) => !chore.isCompleted && chore.title == source.title),
      hasLength(1),
    );

    final undoSource = source.copyWith(
      id: 10,
      title: 'Wash dishes',
    );
    WebMemoryStore.chores
      ..clear()
      ..add(undoSource);
    final undoResult = await service.toggleComplete(undoSource);

    expect(undoResult.createdNextChoreId, isNotNull);
    expect(WebMemoryStore.chores, hasLength(2));

    await service.undoCompletion(undoSource, undoResult);

    expect(WebMemoryStore.chores, hasLength(1));
    expect(
      WebMemoryStore.chores
          .firstWhere((chore) => chore.id == undoSource.id)
          .isCompleted,
      isFalse,
    );
  });

  test('Editing a chore keeps it inside the signed-in household', () async {
    WebMemoryStore.persistenceEnabled = false;
    addTearDown(() => WebMemoryStore.persistenceEnabled = true);
    final now = DateTime.now();
    AuthService.instance.currentUser = AppUser(
      id: 1,
      email: 'bb@gmail.com',
      passwordHash: 'hash',
      displayName: 'bb',
      householdId: 1,
      memberId: 1,
      createdAt: now,
    );
    WebMemoryStore.chores
      ..clear()
      ..add(
        Chore(
          id: 1,
          title: 'Old title',
          assignedMemberId: 1,
          isCompleted: false,
          createdAt: now,
          householdId: 1,
        ),
      );
    addTearDown(_clearHomeData);

    await ChoreService().updateChore(
      Chore(
        id: 1,
        title: 'Updated title',
        assignedMemberId: 1,
        isCompleted: false,
        createdAt: now,
      ),
    );

    final saved = WebMemoryStore.chores.single;
    expect(saved.title, 'Updated title');
    expect(saved.householdId, 1);
    expect(await ChoreService().getAllChores(), hasLength(1));
  });

  test('Invite codes are normalized when pasted', () {
    expect(AuthService.normalizeInviteCode('ur-qzatch'), 'UR-QZATCH');
    expect(AuthService.normalizeInviteCode(' qzatch '), 'UR-QZATCH');
    expect(
      AuthService.normalizeInviteCode('Invite code: UR QZATCH'),
      'UR-QZATCH',
    );
  });

  test('A second local account can find a household by pasted code', () async {
    WebMemoryStore.households
      ..clear()
      ..add(
        Household(
          id: 1,
          name: 'aa\'s Home',
          inviteCode: 'UR-QZATCH',
          createdAt: DateTime(2026, 6, 11),
        ),
      );
    addTearDown(WebMemoryStore.households.clear);

    final code = AuthService.normalizeInviteCode(
      'Invite code: ur qzatch',
    );
    final household = await AccountDao().getHouseholdByCode(code);

    expect(household?.name, 'aa\'s Home');
  });

  testWidgets('Household setup uses the signed-in name and shows back',
      (tester) async {
    AuthService.instance.currentUser = AppUser(
      id: 1,
      email: 'aa@gmail.com',
      passwordHash: 'hash',
      displayName: 'aa',
      createdAt: DateTime(2026, 6, 11),
    );
    addTearDown(() {
      AuthService.instance.currentUser = null;
      AuthService.instance.currentHousehold = null;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: HouseholdSetupScreen(onCompleted: () {}),
      ),
    );

    expect(find.text("aa's Home"), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('Empty Home motivates the signed-in member to add a chore',
      (tester) async {
    _seedHomeUser();
    addTearDown(_clearHomeData);

    await tester.pumpWidget(
      const MaterialApp(home: HomeScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hey bb'), findsOneWidget);
    expect(find.text('Nothing assigned to you yet'), findsOneWidget);
    expect(find.text('Add chore'), findsOneWidget);
    expect(find.text('Templates'), findsOneWidget);
    expect(find.byIcon(Icons.person), findsNothing);
  });

  testWidgets('Home shows every assigned chore with its due date',
      (tester) async {
    final now = DateTime.now();
    final dueDate = DateTime(now.year, now.month, now.day + 1);
    _seedHomeUser();
    WebMemoryStore.chores.add(
      Chore(
        id: 1,
        title: 'Clean the kitchen',
        assignedMemberId: 1,
        dueDate: dueDate,
        isCompleted: false,
        createdAt: now,
        householdId: 1,
      ),
    );
    addTearDown(_clearHomeData);

    await tester.pumpWidget(
      const MaterialApp(home: HomeScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your chores'), findsOneWidget);
    expect(find.text('Clean the kitchen'), findsOneWidget);
    expect(find.text(DateFormat('MMM d').format(dueDate)), findsOneWidget);
  });

  testWidgets('Home marks every upcoming day for a daily chore',
      (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _seedHomeUser();
    WebMemoryStore.chores.add(
      Chore(
        id: 1,
        title: 'Daily tidy',
        assignedMemberId: 1,
        dueDate: today,
        isCompleted: false,
        createdAt: today,
        recurrence: 'daily',
        householdId: 1,
      ),
    );
    addTearDown(_clearHomeData);

    await tester.pumpWidget(
      const MaterialApp(home: HomeScreen()),
    );
    await tester.pumpAndSettle();

    final remainingDays = 8 - today.weekday;
    expect(find.byKey(const ValueKey('missing-dot')), findsNothing);
    for (var offset = 0; offset < remainingDays; offset++) {
      final date = today.add(Duration(days: offset));
      final key = 'chore-dot-${DateFormat('yyyy-MM-dd').format(date)}';
      expect(find.byKey(ValueKey(key)), findsOneWidget);
    }
  });

  testWidgets('Home hides completed history and shows only active chores',
      (tester) async {
    final now = DateTime.now();
    _seedHomeUser();
    WebMemoryStore.chores.addAll([
      Chore(
        id: 1,
        title: 'Make the bed',
        assignedMemberId: 1,
        dueDate: now,
        isCompleted: true,
        createdAt: now.subtract(const Duration(days: 1)),
        recurrence: 'daily',
        householdId: 1,
      ),
      Chore(
        id: 2,
        title: 'Make the bed',
        assignedMemberId: 1,
        dueDate: now.add(const Duration(days: 1)),
        isCompleted: false,
        createdAt: now,
        recurrence: 'daily',
        householdId: 1,
      ),
    ]);
    addTearDown(_clearHomeData);

    await tester.pumpWidget(
      const MaterialApp(home: HomeScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Make the bed'), findsOneWidget);
    expect(find.text('1 still to do'), findsOneWidget);
  });

  testWidgets('Members uses the signed-in user avatar for their row',
      (tester) async {
    AuthService.instance.currentUser = AppUser(
      id: 1,
      email: 'abdullah@gmail.com',
      passwordHash: 'hash',
      displayName: 'abdullah',
      avatarType: 'hedgehog',
      avatarValue: 'assets/images/profile_icons/hedgehog_02.jpg',
      householdId: 1,
      memberId: 1,
      role: 'owner',
      createdAt: DateTime(2026, 6, 11),
    );
    WebMemoryStore.members
      ..clear()
      ..add(
        Member(
          id: 1,
          name: 'abdullah',
          colorHex: '5C8B6E',
          avatarType: 'default',
          householdId: 1,
          createdAt: DateTime(2026, 6, 11),
        ),
      );
    addTearDown(_clearHomeData);

    await tester.pumpWidget(
      const MaterialApp(home: MembersScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Icons.person), findsNothing);
  });

  testWidgets('Undo notifications dismiss automatically', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                showAppNotification(
                  context,
                  'Chore completed.',
                  actionLabel: 'Undo',
                  onAction: () {},
                );
              },
              child: const Text('Show'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.persist, isFalse);
    expect(snackBar.duration, const Duration(seconds: 3));
    expect(find.text('Undo'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
  });
}

void _seedHomeUser() {
  AuthService.instance.currentUser = AppUser(
    id: 1,
    email: 'bb@gmail.com',
    passwordHash: 'hash',
    displayName: 'bb',
    householdId: 1,
    memberId: 1,
    createdAt: DateTime(2026, 6, 11),
  );
  WebMemoryStore.members
    ..clear()
    ..add(
      Member(
        id: 1,
        name: 'bb',
        colorHex: '5C8B6E',
        householdId: 1,
        createdAt: DateTime(2026, 6, 11),
      ),
    );
  WebMemoryStore.chores.clear();
}

void _clearHomeData() {
  AuthService.instance.currentUser = null;
  AuthService.instance.currentHousehold = null;
  WebMemoryStore.members.clear();
  WebMemoryStore.chores.clear();
}
