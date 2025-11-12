import 'package:shared_preferences/shared_preferences.dart';
import 'package:quikxchat/config/setting_keys.dart';

/// Кэш для настроек приложения с автоматической инвалидацией
class SettingsCache {
  static final Map<String, dynamic> _cache = <String, dynamic>{};
  static bool _enabled = true;

  /// Включить/выключить кэширование (для отладки)
  static void setEnabled(bool enabled) {
    _enabled = enabled;
    if (!enabled) {
      clearCache();
    }
  }

  /// Получить значение настройки с кэшированием
  static T getSetting<T>(AppSettings<T> setting, SharedPreferences store) {
    if (!_enabled) {
      return _getItemDirectly(setting, store);
    }

    final key = setting.key;
    if (_cache.containsKey(key)) {
      return _cache[key] as T;
    }

    final value = _getItemDirectly(setting, store);
    _cache[key] = value;
    return value;
  }

  // Внутренний метод для получения значения напрямую
  static T _getItemDirectly<T>(AppSettings<T> setting, SharedPreferences store) {
    // Поскольку extension методы не работают напрямую с обобщённым типом,
    // используем конкретные вызовы для каждого типа
    final String key = setting.key;
    final T defaultValue = setting.defaultValue;
    
    if (T == String) {
      return store.getString(key) as T? ?? defaultValue;
    } else if (T == bool) {
      return store.getBool(key) as T? ?? defaultValue;
    } else if (T == int) {
      return store.getInt(key) as T? ?? defaultValue;
    } else if (T == double) {
      return store.getDouble(key) as T? ?? defaultValue;
    } else {
      // Для неизвестных типов возвращаем значение по умолчанию
      return defaultValue;
    }
  }

  /// Установить значение настройки и обновить кэш
  static Future<void> setSetting<T>(AppSettings<T> setting, SharedPreferences store, T value) async {
    final String key = setting.key;
    
    if (T == String) {
      await store.setString(key, value as String);
    } else if (T == bool) {
      await store.setBool(key, value as bool);
    } else if (T == int) {
      await store.setInt(key, value as int);
    } else if (T == double) {
      await store.setDouble(key, value as double);
    }
    
    _cache[key] = value;
  }

  /// Принудительно обновить значение в кэше
  static void updateCacheValue(String key, dynamic value) {
    _cache[key] = value;
  }

  /// Инвалидировать конкретную настройку в кэше
  static void invalidateSetting(String key) {
    _cache.remove(key);
  }

  /// Очистить весь кэш настроек
  static void clearCache() {
    _cache.clear();
  }

  /// Получить количество закэшированных значений
  static int get cacheSize => _cache.length;

  /// Проверить, есть ли значение в кэше
  static bool isCached(String key) => _cache.containsKey(key);

  /// Получить все ключи в кэше (для отладки)
  static Set<String> get cachedKeys => Set.from(_cache.keys);
}