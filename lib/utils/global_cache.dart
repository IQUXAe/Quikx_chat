import 'dart:typed_data';
import 'package:matrix/matrix.dart';

/// Глобальный кеш для оптимизации приложения
class GlobalCache {
  static final GlobalCache _instance = GlobalCache._internal();
  factory GlobalCache() => _instance;
  GlobalCache._internal();

  // Кеш обоев чатов
  final Map<String, Uint8List> _wallpaperCache = {};
  
  // Кеш сообщений по комнатам
  final Map<String, List<Event>> _messageCache = {};
  
  // Кеш аватаров пользователей
  final Map<String, Uint8List> _avatarCache = {};
  
  // Кеш изображений
  final Map<String, Uint8List> _imageCache = {};
  
  // Максимальные размеры кешей
  static const int _maxWallpaperCache = 10;
  static const int _maxMessageCache = 50;
  static const int _maxAvatarCache = 100;
  static const int _maxImageCache = 200;

  /// Кеш обоев
  void cacheWallpaper(String roomId, Uint8List data) {
    if (_wallpaperCache.length >= _maxWallpaperCache) {
      final firstKey = _wallpaperCache.keys.first;
      _wallpaperCache.remove(firstKey);
    }
    _wallpaperCache[roomId] = data;
  }

  Uint8List? getWallpaper(String roomId) {
    return _wallpaperCache[roomId];
  }

  /// Кеш сообщений
  void cacheMessages(String roomId, List<Event> events) {
    if (_messageCache.length >= _maxMessageCache) {
      final firstKey = _messageCache.keys.first;
      _messageCache.remove(firstKey);
    }
    _messageCache[roomId] = List.from(events);
  }

  List<Event>? getMessages(String roomId) {
    return _messageCache[roomId];
  }

  void addMessage(String roomId, Event event) {
    final messages = _messageCache[roomId];
    if (messages != null) {
      messages.insert(0, event);
      // Ограничиваем количество кешированных сообщений
      if (messages.length > 100) {
        messages.removeRange(100, messages.length);
      }
    }
  }

  /// Кеш аватаров
  void cacheAvatar(String userId, Uint8List data) {
    if (_avatarCache.length >= _maxAvatarCache) {
      final firstKey = _avatarCache.keys.first;
      _avatarCache.remove(firstKey);
    }
    _avatarCache[userId] = data;
  }

  Uint8List? getAvatar(String userId) {
    return _avatarCache[userId];
  }

  /// Кеш изображений
  void cacheImage(String key, Uint8List data) {
    if (_imageCache.length >= _maxImageCache) {
      final firstKey = _imageCache.keys.first;
      _imageCache.remove(firstKey);
    }
    _imageCache[key] = data;
  }

  Uint8List? getImage(String key) {
    return _imageCache[key];
  }

  /// Очистка кеша конкретной комнаты
  void clearRoomCache(String roomId) {
    _wallpaperCache.remove(roomId);
    _messageCache.remove(roomId);
  }

  /// Очистка всего кеша (при выходе из приложения)
  void clearAll() {
    _wallpaperCache.clear();
    _messageCache.clear();
    _avatarCache.clear();
    _imageCache.clear();
  }

  /// Получение размера кеша в байтах (приблизительно)
  int getCacheSize() {
    int size = 0;
    
    for (final data in _wallpaperCache.values) {
      size += data.length;
    }
    
    for (final data in _avatarCache.values) {
      size += data.length;
    }
    
    for (final data in _imageCache.values) {
      size += data.length;
    }
    
    // Примерная оценка размера событий (1KB на событие)
    for (final events in _messageCache.values) {
      size += events.length * 1024;
    }
    
    return size;
  }

  /// Получение статистики кеша
  Map<String, int> getCacheStats() {
    return {
      'wallpapers': _wallpaperCache.length,
      'messages': _messageCache.values.fold(0, (sum, events) => sum + events.length),
      'avatars': _avatarCache.length,
      'images': _imageCache.length,
      'total_size_mb': (getCacheSize() / (1024 * 1024)).round(),
    };
  }
}