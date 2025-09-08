import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:matrix/matrix.dart';

class FileLogger {
  static File? _logFile;
  
  static Future<void> init() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _logFile = File('${directory.path}/push_debug.log');
      await _logFile!.writeAsString('=== Push Debug Log Started ===\n', mode: FileMode.append);
    } catch (e) {
      Logs().w('[FileLogger] Failed to init: $e');
    }
  }
  
  static void log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $message\n';
    
    // Обычный лог
    Logs().i(message);
    
    // Лог в файл
    try {
      _logFile?.writeAsString(logMessage, mode: FileMode.append);
    } catch (e) {
      // Игнорируем ошибки записи в файл
    }
  }
}