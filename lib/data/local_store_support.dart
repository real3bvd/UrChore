export 'local_store_support_stub.dart'
    if (dart.library.html) 'local_store_support_web.dart'
    if (dart.library.io) 'local_store_support_io.dart';
