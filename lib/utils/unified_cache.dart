import 'dart:async';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quikxchat/utils/global_cache.dart';

/// Унифицированная система кэширования с поддержкой персистентности
class UnifiedCache {
  static final UnifiedCache _instance = UnifiedCache._internal();
  factory UnifiedCache() => _instance;
  UnifiedCache._internal();

  final GlobalCache<String, dynamic> _memoryCache = GlobalCache(maxSize: 1000);
  final Map<String, dynamic> _runtimeCache = {};
  Timer? _cleanupTimer;

  /// Инициализация кэша
  Future<void> initialize() async {
    await _loadPersistentData();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) => _cleanup());
  }

  /// Загрузка персистентных данных из SharedPreferences
  Future<void> _loadPersistentData() async {
    try {
      // Кэш переводов может быть загружен из SharedPreferences
      // Пока что оставляем как есть, но в будущем можно интегрировать
    } catch (e) {
      Logs().w('Failed to load persistent cache data: $e');
    }
  }

  /// Получить значение из кэша
  V? get<V>(String key, {String? category}) {
    // Сначала проверяем runtime кэш
    final runtimeKey = _getRuntimeKey(key, category);
    if (_runtimeCache.containsKey(runtimeKey)) {
      return _runtimeCache[runtimeKey] as V?;
    }

    // Затем проверяем memory кэш
    final memoryKey = _getMemoryKey(key, category);
    return _memoryCache.get(memoryKey);
  }

  /// Поместить значение в кэш
  void put<V>(String key, V value, {String? category, bool persistent = false}) {
    final memoryKey = _getMemoryKey(key, category);
    _memoryCache.put(memoryKey, value);

    if (persistent) {
      final runtimeKey = _getRuntimeKey(key, category);
      _runtimeCache[runtimeKey] = value;
      _saveToPersistent(key, value, category: category);
    }
  }

  /// Удалить значение из кэша
  void remove(String key, {String? category}) {
    final memoryKey = _getMemoryKey(key, category);
    _memoryCache.remove(memoryKey);

    final runtimeKey = _getRuntimeKey(key, category);
    _runtimeCache.remove(runtimeKey);
    
    _removeFromPersistent(key, category: category);
  }

  /// Очистить все кэши
  void clear() {
    _memoryCache.clear();
    _runtimeCache.clear();
    _clearPersistent();
  }

  /// Получить ключ для runtime кэша
  String _getRuntimeKey(String key, String? category) => '${category ?? "default"}_rt_$key';

  /// Получить ключ для memory кэша
  String _getMemoryKey(String key, String? category) => '${category ?? "default"}_$key';

  /// Сохранить в персистентное хранилище
  Future<void> _saveToPersistent(String key, dynamic value, {String? category}) async {
    if (value == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final persistentKey = '${category ?? "default"}_persistent_$key';
      
      if (value is String) {
        await prefs.setString(persistentKey, value);
      } else if (value is int) {
        await prefs.setInt(persistentKey, value);
      } else if (value is double) {
        await prefs.setDouble(persistentKey, value);
      } else if (value is bool) {
        await prefs.setBool(persistentKey, value);
      } else if (value is List<String>) {
        await prefs.setStringList(persistentKey, value);
      } else {
        // Для сложных объектов сохраняем как JSON
        await prefs.setString(persistentKey, value.toString());
      }
    } catch (e) {
      Logs().w('Failed to save to persistent cache: $e');
    }
  }

  /// Удалить из персистентного хранилища
  Future<void> _removeFromPersistent(String key, {String? category}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final persistentKey = '${category ?? "default"}_persistent_$key';
      await prefs.remove(persistentKey);
    } catch (e) {
      Logs().w('Failed to remove from persistent cache: $e');
    }
  }

  /// Очистить персистентное хранилище
  Future<void> _clearPersistent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.contains('_persistent_'));
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      Logs().w('Failed to clear persistent cache: $e');
    }
  }

  /// Очистка устаревших данных
  void _cleanup() {
    // Пока просто вызываем cleanup из внутреннего кэша
    // В будущем можно добавить более сложную логику
  }

  /// Освободить ресурсы
  void dispose() {
    _cleanupTimer?.cancel();
    _memoryCache.dispose();
    _runtimeCache.clear();
  }
}