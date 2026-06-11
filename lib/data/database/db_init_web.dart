import '../web_memory_store.dart';

/// Web uses a browser-local store in the DAO layer.
/// Android, iOS, and desktop still use SQLite.
Future<void> initDatabase() => WebMemoryStore.initialize();
