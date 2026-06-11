import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_avatar.dart';
import '../../domain/chore_service.dart';
import '../../domain/member_service.dart';
import '../../domain/auth_service.dart';
import '../../domain/theme_service.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onAuthChanged;

  const SettingsScreen({super.key, required this.onAuthChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ChoreService _choreService = ChoreService();
  final MemberService _memberService = MemberService();

  Future<void> _editProfile() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    if (changed == true && mounted) setState(() {});
  }

  Future<void> _copyInviteCode() async {
    final code = AuthService.instance.currentHousehold?.inviteCode;
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite code copied.')),
      );
    }
  }

  Future<void> _signOut() async {
    await AuthService.instance.signOut();
    widget.onAuthChanged();
  }

  Future<void> _resetAllChores() async {
    final confirmed = await _showConfirmDialog(
      title: 'Reset all chores?',
      body: 'This will permanently delete all chores. Members will be kept.',
      confirmLabel: 'Reset Chores',
    );
    if (confirmed == true) {
      await _choreService.deleteAllChores();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All chores have been reset.')),
        );
      }
    }
  }

  Future<void> _resetEverything() async {
    final confirmed = await _showConfirmDialog(
      title: 'Reset everything?',
      body:
          'This will permanently delete all chores and all members. This action cannot be undone.',
      confirmLabel: 'Reset Everything',
    );
    if (confirmed == true) {
      await _choreService.deleteAllChores();
      await _memberService.deleteAllMembers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data has been reset.')),
        );
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String body,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        content: Text(body, style: Theme.of(context).textTheme.bodyMedium),
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
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('ACCOUNT'),
            _buildAccountSection(),
            const SizedBox(height: 32),

            _sectionLabel('APPEARANCE'),
            _buildAppearanceSection(),
            const SizedBox(height: 32),

            // About section
            _sectionLabel('ABOUT'),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 1),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      'UrChore',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      'Home Chores Assignment App',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text(
                      'Version',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    trailing: Text(
                      '1.0.0',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Data section
            _sectionLabel('DATA'),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 1),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      'Reset all chores',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    subtitle: Text(
                      'Deletes all chores but keeps members',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    trailing: Icon(Icons.chevron_right,
                        color: Theme.of(context).colorScheme.outline, size: 20),
                    onTap: _resetAllChores,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text(
                      'Reset everything',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: AppColors.overdue),
                    ),
                    subtitle: Text(
                      'Deletes all chores and members',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    trailing: Icon(Icons.chevron_right,
                        color: Theme.of(context).colorScheme.outline, size: 20),
                    onTap: _resetEverything,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
            ),
            const SizedBox(height: 32),

            // Footer
            Center(
              child: Text(
                'Made with care',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    final user = AuthService.instance.currentUser!;
    final household = AuthService.instance.currentHousehold;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          ListTile(
            leading: ProfileAvatar(
              name: user.displayName,
              avatarType: user.avatarType,
              avatarValue: user.avatarValue,
              colorHex: user.colorHex,
              size: 46,
            ),
            title: Text(
              user.displayName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              user.email,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _editProfile,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: Text(
              household?.name ?? 'Household',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            subtitle: Text(
              'Invite code: ${household?.inviteCode ?? '-'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            trailing: IconButton(
              tooltip: 'Copy invite code',
              onPressed: _copyInviteCode,
              icon: const Icon(Icons.copy_outlined),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance.themeMode,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: SwitchListTile(
            value: isDark,
            onChanged: ThemeService.instance.setDarkMode,
            secondary: Icon(
              isDark ? Icons.dark_mode : Icons.dark_mode_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              'Dark mode',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            subtitle: Text(
              'Use warm dark colors throughout the app',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        );
      },
    );
  }
}
