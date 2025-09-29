import 'dart:collection';
import 'dart:async';

/// Глобальный кэш с автоматической очисткой и лимитами по размеру
class GlobalCache<K, V> {
  final int maxSize;
  final Duration? expireAfter;
  final LinkedHashMap<K, _CacheEntry<V>> _cache = LinkedHashMap();
  Timer? _cleanupTimer;

  GlobalCache({
    this.maxSize = 1000,
    this.expireAfter,
  }) {
    if (expireAfter != null) {
      _cleanupTimer = Timer.periodic(
        const Duration(minutes: 5),
        (_) => _cleanupExpired(),
      );
    }
  }

  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) return null;

    // Проверяем не истек ли срок
    if (expireAfter != null && 
        DateTime.now().difference(entry.timestamp) > expireAfter!) {
      _cache.remove(key);
      return null;
    }

    // Перемещаем в конец для LRU
    _cache.remove(key);
    _cache[key] = entry;
    
    return entry.value;
  }

  void put(K key, V value) {
    // Удаляем старое значение если есть
    _cache.remove(key);

    // Добавляем новое
    _cache[key] = _CacheEntry(value, DateTime.now());

    // Проверяем лимит размера
    while (_cache.length > maxSize) {
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
    }
  }

  void remove(K key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
  }

  int get length => _cache.length;

  void _cleanupExpired() {
    if (expireAfter == null) return;

    final now = DateTime.now();
    final keysToRemove = <K>[];

    for (final entry in _cache.entries) {
      if (now.difference(entry.value.timestamp) > expireAfter!) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _cache.clear();
  }
}

class _CacheEntry<V> {
  final V value;
  final DateTime timestamp;

  _CacheEntry(this.value, this.timestamp);
}

/// Кэши для различных типов данных
class AppCaches {
  static final profiles = GlobalCache<String, Map<String, dynamic>>(
    maxSize: 500,
    expireAfter: const Duration(hours: 1),
  );

  static final avatars = GlobalCache<String, String>(
    maxSize: 200,
    expireAfter: const Duration(hours: 2),
  );

  static final eventContents = GlobalCache<String, Map<String, dynamic>>(
    maxSize: 1000,
    expireAfter: const Duration(minutes: 30),
  );

  static final translations = GlobalCache<String, String>(
    maxSize: 500,
    expireAfter: const Duration(hours: 1),
  );

  static void disposeAll() {
    profiles.dispose();
    avatars.dispose();
    eventContents.dispose();
    translations.dispose();
  }

  static void clearAll() {
    profiles.clear();
    avatars.clear();
    eventContents.clear();
    translations.clear();
  }

  static Map<String, int> getStats() {
    return {
      'profiles': profiles.length,
      'avatars': avatars.length,
      'eventContents': eventContents.length,
      'translations': translations.length,
    };
  }
}
