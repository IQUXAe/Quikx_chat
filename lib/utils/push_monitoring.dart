import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quikxchat/config/setting_keys.dart';
import 'package:quikxchat/utils/network_error_handler.dart';

/// Мониторинг и диагностика пуш-уведомлений
class PushMonitoring {
  static const String _keyLastPushReceived = 'last_push_received';
  static const String _keyPushStats = 'push_stats';
  static const String _keyPushErrors = 'push_errors';
  
  /// Записывает получение пуш-уведомления
  static Future<void> recordPushReceived({
    required String roomId,
    required String eventId,
    String? error,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Записываем время последнего получения
      await prefs.setInt(_keyLastPushReceived, now);
      
      // Обновляем статистику
      await _updatePushStats(prefs, error == null);
      
      // Записываем ошибку если есть
      if (error != null) {
        await _recordPushError(prefs, error, roomId, eventId);
      }
      
      Logs().i('[PushMonitoring] Recorded push: room=$roomId, event=$eventId, error=$error');
    } catch (e) {
      Logs().e('[PushMonitoring] Failed to record push', e);
    }
  }
  
  /// Проверяет здоровье пуш-уведомлений
  static Future<PushHealthStatus> checkPushHealth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Проверяем время последнего получения
      final lastReceived = prefs.getInt(_keyLastPushReceived);
      final timeSinceLastPush = lastReceived != null 
          ? Duration(milliseconds: now - lastReceived)
          : null;
      
      // Получаем статистику
      final stats = await _getPushStats(prefs);
      final errors = await _getRecentErrors(prefs);
      
      // Определяем статус здоровья
      PushHealthLevel healthLevel;
      final issues = <String>[];
      
      if (timeSinceLastPush == null) {
        healthLevel = PushHealthLevel.unknown;
        issues.add('No push notifications received yet');
      } else if (timeSinceLastPush.inHours > 24) {
        healthLevel = PushHealthLevel.critical;
        issues.add('No push notifications received in ${timeSinceLastPush.inHours} hours');
      } else if (timeSinceLastPush.inHours > 6) {
        healthLevel = PushHealthLevel.warning;
        issues.add('No push notifications received in ${timeSinceLastPush.inHours} hours');
      } else if (stats.errorRate > 0.5) {
        healthLevel = PushHealthLevel.warning;
        issues.add('High error rate: ${(stats.errorRate * 100).toStringAsFixed(1)}%');
      } else {
        healthLevel = PushHealthLevel.healthy;
      }
      
      // Добавляем сетевые проблемы
      if (!await NetworkErrorHandler.isNetworkAvailable()) {
        healthLevel = PushHealthLevel.critical;
        issues.add('Network not available');
      }
      
      return PushHealthStatus(
        level: healthLevel,
        lastPushReceived: lastReceived != null 
            ? DateTime.fromMillisecondsSinceEpoch(lastReceived)
            : null,
        timeSinceLastPush: timeSinceLastPush,
        stats: stats,
        recentErrors: errors,
        issues: issues,
      );
    } catch (e) {
      Logs().e('[PushMonitoring] Failed to check push health', e);
      return PushHealthStatus(
        level: PushHealthLevel.unknown,
        issues: ['Failed to check health: $e'],
        stats: PushStats.empty(),
        recentErrors: [],
      );
    }
  }
  
  /// Получает диагностическую информацию
  static Future<Map<String, dynamic>> getDiagnosticInfo() async {
    final info = <String, dynamic>{};
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final health = await checkPushHealth();
      
      info['health'] = {
        'level': health.level.name,
        'issues': health.issues,
        'last_push_received': health.lastPushReceived?.toIso8601String(),
        'time_since_last_push_hours': health.timeSinceLastPush?.inHours,
      };
      
      info['stats'] = {
        'total_received': health.stats.totalReceived,
        'total_errors': health.stats.totalErrors,
        'error_rate': health.stats.errorRate,
        'success_rate': health.stats.successRate,
      };
      
      info['recent_errors'] = health.recentErrors.map((e) => {
        'timestamp': e.timestamp.toIso8601String(),
        'error': e.error,
        'room_id': e.roomId,
        'event_id': e.eventId,
      },).toList();
      
      // Добавляем системную информацию
      info['system'] = {
        'platform': Platform.operatingSystem,
        'network_available': await NetworkErrorHandler.isNetworkAvailable(),
      };
      
      // Добавляем настройки UnifiedPush
      info['unified_push'] = {
        'registered': prefs.getBool(SettingKeys.unifiedPushRegistered) ?? false,
        'endpoint': prefs.getString(SettingKeys.unifiedPushEndpoint),
      };
      
    } catch (e) {
      info['error'] = e.toString();
    }
    
    return info;
  }
  
  /// Очищает старые данные мониторинга
  static Future<void> cleanup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Очищаем старые ошибки (старше 7 дней)
      final errors = await _getRecentErrors(prefs, maxAge: const Duration(days: 7));
      await prefs.setString(_keyPushErrors, json.encode(
        errors.map((e) => e.toJson()).toList(),
      ),);
      
      Logs().i('[PushMonitoring] Cleanup completed');
    } catch (e) {
      Logs().e('[PushMonitoring] Cleanup failed', e);
    }
  }
  
  static Future<void> _updatePushStats(SharedPreferences prefs, bool success) async {
    final statsJson = prefs.getString(_keyPushStats);
    PushStats stats;
    
    if (statsJson != null) {
      try {
        stats = PushStats.fromJson(json.decode(statsJson));
      } catch (e) {
        stats = PushStats.empty();
      }
    } else {
      stats = PushStats.empty();
    }
    
    stats = PushStats(
      totalReceived: stats.totalReceived + 1,
      totalErrors: success ? stats.totalErrors : stats.totalErrors + 1,
    );
    
    await prefs.setString(_keyPushStats, json.encode(stats.toJson()));
  }
  
  static Future<PushStats> _getPushStats(SharedPreferences prefs) async {
    final statsJson = prefs.getString(_keyPushStats);
    if (statsJson != null) {
      try {
        return PushStats.fromJson(json.decode(statsJson));
      } catch (e) {
        return PushStats.empty();
      }
    }
    return PushStats.empty();
  }
  
  static Future<void> _recordPushError(
    SharedPreferences prefs,
    String error,
    String roomId,
    String eventId,
  ) async {
    final errors = await _getRecentErrors(prefs);
    
    errors.add(PushError(
      timestamp: DateTime.now(),
      error: error,
      roomId: roomId,
      eventId: eventId,
    ),);
    
    // Ограничиваем количество ошибок
    if (errors.length > 100) {
      errors.removeRange(0, errors.length - 100);
    }
    
    await prefs.setString(_keyPushErrors, json.encode(
      errors.map((e) => e.toJson()).toList(),
    ),);
  }
  
  static Future<List<PushError>> _getRecentErrors(
    SharedPreferences prefs, {
    Duration maxAge = const Duration(days: 1),
  }) async {
    final errorsJson = prefs.getString(_keyPushErrors);
    if (errorsJson == null) return [];
    
    try {
      final errorsList = json.decode(errorsJson) as List;
      final now = DateTime.now();
      
      return errorsList
          .map((e) => PushError.fromJson(e))
          .where((error) => now.difference(error.timestamp) <= maxAge)
          .toList();
    } catch (e) {
      return [];
    }
  }
}

enum PushHealthLevel {
  healthy,
  warning,
  critical,
  unknown,
}

class PushHealthStatus {
  final PushHealthLevel level;
  final DateTime? lastPushReceived;
  final Duration? timeSinceLastPush;
  final PushStats stats;
  final List<PushError> recentErrors;
  final List<String> issues;
  
  const PushHealthStatus({
    required this.level,
    this.lastPushReceived,
    this.timeSinceLastPush,
    required this.stats,
    required this.recentErrors,
    required this.issues,
  });
}

class PushStats {
  final int totalReceived;
  final int totalErrors;
  
  const PushStats({
    required this.totalReceived,
    required this.totalErrors,
  });
  
  factory PushStats.empty() => const PushStats(totalReceived: 0, totalErrors: 0);
  
  double get errorRate => totalReceived > 0 ? totalErrors / totalReceived : 0.0;
  double get successRate => 1.0 - errorRate;
  
  factory PushStats.fromJson(Map<String, dynamic> json) {
    return PushStats(
      totalReceived: json['total_received'] ?? 0,
      totalErrors: json['total_errors'] ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'total_received': totalReceived,
      'total_errors': totalErrors,
    };
  }
}

class PushError {
  final DateTime timestamp;
  final String error;
  final String roomId;
  final String eventId;
  
  const PushError({
    required this.timestamp,
    required this.error,
    required this.roomId,
    required this.eventId,
  });
  
  factory PushError.fromJson(Map<String, dynamic> json) {
    return PushError(
      timestamp: DateTime.parse(json['timestamp']),
      error: json['error'],
      roomId: json['room_id'],
      eventId: json['event_id'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'error': error,
      'room_id': roomId,
      'event_id': eventId,
    };
  }
}