import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/chores_screen.dart';
import 'ui/screens/members_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/household_setup_screen.dart';
import 'ui/screens/welcome_screen.dart';
import 'ui/widgets/hedgehog_painter.dart';
import 'domain/auth_service.dart';
import 'ui/theme/theme_service.dart';

// Conditional import: picks the right DB init for web vs native
import 'data/database/db_init_stub.dart'
    if (dart.library.html) 'data/database/db_init_web.dart'
    if (dart.library.io) 'data/database/db_init_native.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the persistent store for the current platform.
  await initDatabase();
  await ThemeService.instance.initialize();

  // SystemChrome is a no-op on web but guard it for safety
  if (!kIsWeb) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  runApp(const UrChoreApp());
}

class UrChoreApp extends StatelessWidget {
  const UrChoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance.themeMode,
      builder: (context, themeMode, _) => MaterialApp(
        title: 'UrChore',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: const AppGate(),
      ),
    );
  }
}

class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  late Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = AuthService.instance.initialize();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: HedgehogWidget(
                size: 92,
                activity: HedgehogActivity.waving,
              ),
            ),
          );
        }

        final auth = AuthService.instance;
        if (auth.currentUser == null) {
          return WelcomeScreen(onAuthenticated: _refresh);
        }
        if (auth.currentUser!.householdId == null) {
          return HouseholdSetupScreen(onCompleted: _refresh);
        }
        return MainShell(onAuthChanged: _refresh);
      },
    );
  }
}

class MainShell extends StatefulWidget {
  final VoidCallback onAuthChanged;

  const MainShell({super.key, required this.onAuthChanged});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final GlobalKey<_HomeScreenWrapperState> _homeKey =
      GlobalKey<_HomeScreenWrapperState>();
  final GlobalKey<ChoresScreenState> _choresKey =
      GlobalKey<ChoresScreenState>();
  final GlobalKey<MembersScreenState> _membersKey =
      GlobalKey<MembersScreenState>();

  void _switchToChores() {
    setState(() => _currentIndex = 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeScreenWrapper(
            key: _homeKey,
            onNavigateToChores: _switchToChores,
          ),
          ChoresScreen(key: _choresKey),
          MembersScreen(key: _membersKey),
          SettingsScreen(onAuthChanged: widget.onAuthChanged),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) {
            setState(() => _currentIndex = i);
            // Reload data when switching tabs
            if (i == 0) {
              _homeKey.currentState?._loadData();
            } else if (i == 1) {
              _choresKey.currentState?.loadData();
            } else if (i == 2) {
              _membersKey.currentState?.loadMembers();
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.outline,
          elevation: 0,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.checklist_outlined),
              activeIcon: Icon(Icons.checklist),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: '',
            ),
          ],
        ),
      ),
    );
  }
}

// Wrapper to expose HomeScreen's reload method to the shell
class _HomeScreenWrapper extends StatefulWidget {
  final VoidCallback? onNavigateToChores;

  const _HomeScreenWrapper({super.key, this.onNavigateToChores});

  @override
  State<_HomeScreenWrapper> createState() => _HomeScreenWrapperState();
}

class _HomeScreenWrapperState extends State<_HomeScreenWrapper> {
  void _loadData() {
    // Trigger rebuild by setting state
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreen(
      key: ValueKey(DateTime.now().millisecondsSinceEpoch),
      onNavigateToChores: widget.onNavigateToChores,
    );
  }
}
