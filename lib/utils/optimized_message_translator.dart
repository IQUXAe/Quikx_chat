import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:simplemessenger/utils/message_translator.dart';

class OptimizedMessageTranslator {
  static final Map<String, String> _translationCache = {};
  static const int _maxCacheSize = 200;
  static Timer? _cacheCleanupTimer;
  
  static void initialize() {
    // Периодическая очистка кэша
    _cacheCleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupCache();
    });
  }
  
  static void dispose() {
    _cacheCleanupTimer?.cancel();
    _translationCache.clear();
  }
  
  static void _cleanupCache() {
    if (_translationCache.length > _maxCacheSize) {
      final keys = _translationCache.keys.toList();
      final keysToRemove = keys.take(keys.length - _maxCacheSize ~/ 2);
      for (final key in keysToRemove) {
        _translationCache.remove(key);
      }
    }
  }
  
  static Future<String?> translateMessage(String text, String targetLang) async {
    final cacheKey = '${text.hashCode}_$targetLang';
    
    // Проверяем кэш
    if (_translationCache.containsKey(cacheKey)) {
      return _translationCache[cacheKey];
    }
    
    try {
      // Выполняем перевод в изоляте для больших текстов
      if (text.length > 100) {
        final result = await compute(_translateInIsolate, {
          'text': text,
          'targetLang': targetLang,
        });
        
        if (result != null) {
          _translationCache[cacheKey] = result;
          return result;
        }
      } else {
        // Для коротких текстов используем основной поток
        final result = await MessageTranslator.translateMessage(text, targetLang);
        if (result != null) {
          _translationCache[cacheKey] = result;
          return result;
        }
      }
    } catch (e) {
      // Игнорируем ошибки перевода
    }
    
    return null;
  }
  
  static Future<String?> _translateInIsolate(Map<String, String> data) async {
    try {
      return await MessageTranslator.translateMessage(
        data['text']!,
        data['targetLang']!,
      );
    } catch (e) {
      return null;
    }
  }
  
  static void clearCache() {
    _translationCache.clear();
  }
  
  static int get cacheSize => _translationCache.length;
}