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
import 'package:urchore/ui/screens/avatar_picker_screen.dart';
import 'package:urchore/ui/screens/household_setup_screen.dart';
import 'package:urchore/ui/screens/home_screen.dart';
import 'package:urchore/ui/screens/members_screen.dart';
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
