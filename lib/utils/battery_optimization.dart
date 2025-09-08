import 'dart:io';
import 'package:flutter/services.dart';
import 'package:matrix/matrix.dart';

class BatteryOptimization {
  static const MethodChannel _channel = MethodChannel('battery_optimization');
  
  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    
    try {
      final result = await _channel.invokeMethod('isIgnoringBatteryOptimizations');
      return result ?? false;
    } catch (e) {
      Logs().w('[BatteryOptimization] Failed to check status: $e');
      return false;
    }
  }
  
  static Future<void> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid) return;
    
    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (e) {
      Logs().w('[BatteryOptimization] Failed to request: $e');
    }
  }
}