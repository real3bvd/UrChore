import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  ThemeService._();

  static final ThemeService instance = ThemeService._();
  static const _storageKey = 'urchore_theme_mode_v1';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  Future<void> initialize() async {
    final savedMode = await _preferences.getString(_storageKey);
    themeMode.value = savedMode == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setDarkMode(bool enabled) async {
    final mode = enabled ? ThemeMode.dark : ThemeMode.light;
    if (themeMode.value == mode) return;

    themeMode.value = mode;
    await _preferences.setString(
      _storageKey,
      enabled ? 'dark' : 'light',
    );
  }
}
