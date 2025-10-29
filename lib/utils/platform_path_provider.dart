import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

Future<io.Directory> getTemporaryDirectory() async {
  if (kIsWeb) {
    // Web doesn't support file system, return a dummy directory
    throw UnsupportedError('getTemporaryDirectory is not supported on web');
  }
  return path_provider.getTemporaryDirectory();
}

Future<io.Directory> getApplicationDocumentsDirectory() async {
  if (kIsWeb) {
    throw UnsupportedError('getApplicationDocumentsDirectory is not supported on web');
  }
  return path_provider.getApplicationDocumentsDirectory();
}

Future<io.Directory> getApplicationSupportDirectory() async {
  if (kIsWeb) {
    throw UnsupportedError('getApplicationSupportDirectory is not supported on web');
  }
  return path_provider.getApplicationSupportDirectory();
}
