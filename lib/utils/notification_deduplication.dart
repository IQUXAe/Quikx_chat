import 'dart:async';
import 'package:matrix/matrix.dart';

/// Утилита для предотвращения дублирования уведомлений
class NotificationDeduplication {
  static final Map<String, DateTime> _processedNotifications = {};
  static final Map<String, Timer> _cleanupTimers = {};
  
  /// Проверяет, было ли уведомление уже обработано
  static bool isAlreadyProcessed(String roomId, String eventId) {
    final key = '${roomId}_$eventId';
    final processedTime = _processedNotifications[key];
    
    if (processedTime != null) {
      // Считаем обработанным, если прошло менее 5 минут
      final timeDiff = DateTime.now().difference(processedTime);
      if (timeDiff < const Duration(minutes: 5)) {
        Logs().i('[NotificationDedup] Skipping duplicate: $key');
        return true;
      } else {
        // Удаляем устаревшую запись
        _processedNotifications.remove(key);
        _cleanupTimers[key]?.cancel();
        _cleanupTimers.remove(key);
      }
    }
    
    return false;
  }
  
  /// Отмечает уведомление как обработанное
  static void markAsProcessed(String roomId, String eventId) {
    final key = '${roomId}_$eventId';
    _processedNotifications[key] = DateTime.now();
    
    // Автоматически удаляем через 10 минут
    _cleanupTimers[key]?.cancel();
    _cleanupTimers[key] = Timer(const Duration(minutes: 10), () {
      _processedNotifications.remove(key);
      _cleanupTimers.remove(key);
    });
    
    Logs().v('[NotificationDedup] Marked as processed: $key');
  }
  
  /// Удаляет уведомление из кэша (например, при ошибке обработки)
  static void removeFromCache(String roomId, String eventId) {
    final key = '${roomId}_$eventId';
    _processedNotifications.remove(key);
    _cleanupTimers[key]?.cancel();
    _cleanupTimers.remove(key);
    
    Logs().v('[NotificationDedup] Removed from cache: $key');
  }
  
  /// Очищает весь кэш
  static void clearCache() {
    _processedNotifications.clear();
    for (final timer in _cleanupTimers.values) {
      timer.cancel();
    }
    _cleanupTimers.clear();
    
    Logs().i('[NotificationDedup] Cache cleared');
  }
  
  /// Получает статистику кэша
  static Map<String, dynamic> getStats() {
    return {
      'processed_count': _processedNotifications.length,
      'cleanup_timers_count': _cleanupTimers.length,
      'oldest_entry': _processedNotifications.values.isEmpty 
          ? null 
          : _processedNotifications.values.reduce((a, b) => a.isBefore(b) ? a : b).toIso8601String(),
    };
  }
}