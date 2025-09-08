import 'dart:io';
import 'package:flutter/foundation.dart';

class SecurityUtils {
  // Проверка на отладчик
  static bool get isDebuggerAttached {
    if (kDebugMode) return true;
    return false;
  }

  // Проверка на эмулятор
  static bool get isEmulator {
    if (Platform.isAndroid) {
      return Platform.environment['ANDROID_EMULATOR'] != null;
    }
    return false;
  }

  

  // Базовая защита от реверс-инжиниринга
  static void antiTamper() {
    if (kDebugMode) return;
    
    // Проверки целостности можно добавить здесь
    if (isDebuggerAttached || isEmulator) {
      exit(0);
    }
  }
}