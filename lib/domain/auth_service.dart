import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../data/models/app_user.dart';
import '../data/models/avatar_choice.dart';
import '../data/models/household.dart';
import '../data/models/member.dart';
import '../data/repository/account_repository.dart';
import '../data/repository/member_repository.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final AccountRepository _accountRepo = AccountRepository();
  final MemberRepository _memberRepo = MemberRepository();
  final Random _random = Random.secure();

  AppUser? currentUser;
  Household? currentHousehold;

  Future<void> initialize() async {
    currentUser = await _accountRepo.getSessionUser();
    await _loadCurrentHousehold();
  }

  Future<AppUser> register({
    required String email,
    required String password,
    String? name,
    AvatarChoice avatar = const AvatarChoice(),
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (await _accountRepo.getUserByEmail(normalizedEmail) != null) {
      throw Exception('An account already exists for this email.');
    }

    final fallbackName = normalizedEmail.split('@').first;
    final cleanedName =
        (name?.trim().isNotEmpty == true ? name!.trim() : fallbackName)
            .substring(
      0,
      min(
        30,
        (name?.trim().isNotEmpty == true ? name!.trim() : fallbackName).length,
      ),
    );

    final user = AppUser(
      email: normalizedEmail,
      passwordHash: _hashPassword(password),
      displayName: cleanedName,
      avatarType: avatar.type,
      avatarValue: avatar.value,
      colorHex: avatar.colorHex,
      createdAt: DateTime.now(),
    );

    final id = await _accountRepo.insertUser(user);
    currentUser = user.copyWith(id: id);
    await _accountRepo.setSession(id);
    return currentUser!;
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final user = await _accountRepo.getUserByEmail(email.trim().toLowerCase());
    if (user == null || user.passwordHash != _hashPassword(password)) {
      throw Exception('Incorrect email or password.');
    }

    currentUser = user;
    await _accountRepo.setSession(user.id!);
    await _loadCurrentHousehold();
    return user;
  }

  Future<Household> createHousehold(String name) async {
    final user = _requireUser();
    final household = Household(
      name: name.trim(),
      inviteCode: await _generateInviteCode(),
      createdAt: DateTime.now(),
    );
    final householdId = await _accountRepo.insertHousehold(household);
    final savedHousehold = household.copyWith(id: householdId);
    await _attachUserToHousehold(
      user: user,
      household: savedHousehold,
      role: 'owner',
    );
    return savedHousehold;
  }

  Future<Household?> findHousehold(String inviteCode) {
    return _accountRepo.getHouseholdByCode(
      normalizeInviteCode(inviteCode),
    );
  }

  static String normalizeInviteCode(String input) {
    final compact = input.toUpperCase().replaceAll(
          RegExp(r'[^A-Z0-9]'),
          '',
        );
    final embeddedCode = RegExp(r'UR([A-Z0-9]{6})').firstMatch(compact);
    if (embeddedCode != null) {
      return 'UR-${embeddedCode.group(1)}';
    }
    if (compact.length == 6) {
      return 'UR-$compact';
    }
    return input.trim().toUpperCase();
  }

  Future<void> joinHousehold(Household household) async {
    await _attachUserToHousehold(
      user: _requireUser(),
      household: household,
      role: 'member',
    );
  }

  Future<void> updateProfile({
    required String displayName,
    required AvatarChoice avatar,
  }) async {
    final user = _requireUser();
    final updated = user.copyWith(
      displayName: displayName.trim(),
      avatarType: avatar.type,
      avatarValue: avatar.value,
      colorHex: avatar.colorHex,
      clearAvatarValue: avatar.value == null,
    );
    await _accountRepo.updateUser(updated);

    if (updated.memberId != null) {
      final members = await _memberRepo.getAllMembers();
      final index =
          members.indexWhere((member) => member.id == updated.memberId);
      if (index != -1) {
        final member = members[index].copyWith(
          name: updated.displayName,
          colorHex: updated.colorHex,
          avatarType: updated.avatarType,
          avatarValue: updated.avatarValue,
          clearAvatarValue: updated.avatarValue == null,
        );
        await _memberRepo.updateMember(member);
      }
    }

    currentUser = updated;
  }

  Future<void> signOut() async {
    await _accountRepo.clearSession();
    currentUser = null;
    currentHousehold = null;
  }

  Future<void> _attachUserToHousehold({
    required AppUser user,
    required Household household,
    required String role,
  }) async {
    var memberId = user.memberId;
    if (memberId == null) {
      final member = Member(
        name: user.displayName,
        colorHex: user.colorHex,
        avatarType: user.avatarType,
        avatarValue: user.avatarValue,
        householdId: household.id,
        createdAt: DateTime.now(),
      );
      memberId = await _memberRepo.addMember(member);
    }

    final updatedUser = user.copyWith(
      householdId: household.id,
      memberId: memberId,
      role: role,
    );
    await _accountRepo.updateUser(updatedUser);
    currentUser = updatedUser;
    currentHousehold = household;
  }

  Future<void> _loadCurrentHousehold() async {
    final householdId = currentUser?.householdId;
    currentHousehold = householdId == null
        ? null
        : await _accountRepo.getHouseholdById(householdId);
  }

  Future<String> _generateInviteCode() async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    for (var attempt = 0; attempt < 20; attempt++) {
      final suffix = List.generate(
        6,
        (_) => chars[_random.nextInt(chars.length)],
      ).join();
      final code = 'UR-$suffix';
      if (await _accountRepo.getHouseholdByCode(code) == null) return code;
    }
    throw Exception('Could not create an invite code. Please try again.');
  }

  AppUser _requireUser() {
    final user = currentUser;
    if (user == null) throw Exception('Please sign in first.');
    return user;
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }
}
