import 'package:flutter/material.dart';

import '../../data/models/household.dart';
import '../../domain/auth_service.dart';
import '../widgets/profile_avatar.dart';

class HouseholdSetupScreen extends StatefulWidget {
  final VoidCallback onCompleted;

  const HouseholdSetupScreen({super.key, required this.onCompleted});

  @override
  State<HouseholdSetupScreen> createState() => _HouseholdSetupScreenState();
}

class _HouseholdSetupScreenState extends State<HouseholdSetupScreen> {
  final _householdController = TextEditingController();
  final _codeController = TextEditingController();
  bool _showCreate = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final name = AuthService.instance.currentUser!.displayName.trim();
    _householdController.text = "$name's Home";
  }

  @override
  void dispose() {
    _householdController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _createHousehold() async {
    final name = _householdController.text.trim();
    if (name.isEmpty) {
      _showMessage('Enter a household name.');
      return;
    }
    await _run(() async {
      await AuthService.instance.createHousehold(name);
      widget.onCompleted();
    });
  }

  Future<void> _findAndJoin() async {
    final code = AuthService.normalizeInviteCode(_codeController.text);
    if (code.isEmpty) {
      _showMessage('Enter the invite code.');
      return;
    }
    _codeController.text = code;

    setState(() => _isSaving = true);
    try {
      final household = await AuthService.instance.findHousehold(code);
      if (!mounted) return;
      if (household == null) {
        _showMessage('Household not found. Check the code and try again.');
        return;
      }
      final confirmed = await _confirmHousehold(household);
      if (confirmed == true) {
        await AuthService.instance.joinHousehold(household);
        widget.onCompleted();
      }
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool?> _confirmHousehold(Household household) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Join ${household.name}?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: const Text('You are about to join this household.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Join household'),
          ),
        ],
      ),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _isSaving = true);
    try {
      await action();
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _leaveSetup() async {
    if (_isSaving) return;
    await AuthService.instance.signOut();
    widget.onCompleted();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leaveSetup();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back to welcome',
            onPressed: _isSaving ? null : _leaveSetup,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ProfileAvatar(
                      name: user.displayName,
                      avatarType: user.avatarType,
                      avatarValue: user.avatarValue,
                      colorHex: user.colorHex,
                      size: 58,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            user.email,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                Text(
                  'Set up your household',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a new home or join one using its invite code.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: _ModeButton(
                        label: 'Create',
                        icon: Icons.home_outlined,
                        selected: _showCreate,
                        onTap: () => setState(() => _showCreate = true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ModeButton(
                        label: 'Join',
                        icon: Icons.group_add_outlined,
                        selected: !_showCreate,
                        onTap: () => setState(() => _showCreate = false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                if (_showCreate) ...[
                  TextFormField(
                    controller: _householdController,
                    maxLength: 40,
                    decoration: const InputDecoration(
                      labelText: 'Household name',
                      prefixIcon: Icon(Icons.home_outlined),
                      counterText: '',
                    ),
                    onFieldSubmitted: (_) => _createHousehold(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You will become the household owner and receive an invite code.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ] else ...[
                  TextFormField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Invite code',
                      hintText: 'UR-ABC123',
                      prefixIcon: Icon(Icons.key_outlined),
                    ),
                    onFieldSubmitted: (_) => _findAndJoin(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'The household name will be shown before you confirm. '
                    'This local version can join households saved on this device.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving
                        ? null
                        : (_showCreate ? _createHousehold : _findAndJoin),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_showCreate ? 'Create household' : 'Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
