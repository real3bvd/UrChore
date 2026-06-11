import 'dart:io' show Platform;

bool get useLocalStore => Platform.isWindows || Platform.isLinux;
