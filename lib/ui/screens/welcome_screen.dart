import 'package:flutter/material.dart';

import '../widgets/hedgehog_painter.dart';
import 'register_screen.dart';
import 'sign_in_screen.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onAuthenticated;

  const WelcomeScreen({super.key, required this.onAuthenticated});

  Future<void> _open(BuildContext context, Widget screen) async {
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    if (success == true) return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              const HedgehogWidget(
                size: 132,
                activity: HedgehogActivity.waving,
              ),
              const SizedBox(height: 24),
              Text(
                'UrChore',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 38,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'Keep home chores clear, shared, and easy.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _open(
                    context,
                    RegisterScreen(onRegistered: onAuthenticated),
                  ),
                  child: const Text('Create account'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _open(
                    context,
                    SignInScreen(onSignedIn: onAuthenticated),
                  ),
                  child: const Text('Sign in'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
