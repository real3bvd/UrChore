import 'dart:io' show Platform;

import '../web_memory_store.dart';

/// Android, iOS, and macOS use the native sqflite plugin.
/// Windows and Linux use the same persistent local store as web so builds do
/// not require downloading a separate SQLite native binary.
Future<void> initDatabase() async {
  if (Platform.isWindows || Platform.isLinux) {
    await WebMemoryStore.initialize();
  }
}
