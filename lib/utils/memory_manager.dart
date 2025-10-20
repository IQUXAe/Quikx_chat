import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:matrix/matrix.dart';
import 'global_cache.dart';

class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  static const int _lowMemoryThreshold = 100 * 1024 * 1024; // 100MB
  static const int _maxImageCacheSize = 50 * 1024 * 1024; // 50MB
  static const int _maxImageCacheCount = 100;
  
  Timer? _memoryCheckTimer;
  bool _isOptimizingMemory = false;
  
  void initialize() {
    // Настраиваем лимиты кэша изображений
    PaintingBinding.instance.imageCache.maximumSize = _maxImageCacheCount;
    PaintingBinding.instance.imageCache.maximumSizeBytes = _maxImageCacheSize;
    
    // Запускаем периодическую проверку памяти
    _memoryCheckTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _checkAndOptimizeMemory();
    });

    Logs().i('[MemoryManager] Initialized with limits: $_maxImageCacheCount images, ${_maxImageCacheSize ~/ (1024 * 1024)}MB');
  }
  
  bool get isLowMemory {
    try {
      return ProcessInfo.currentRss > _lowMemoryThreshold * 4;
    } catch (e) {
      return false;
    }
  }
  
  void _checkAndOptimizeMemory() {
    if (_isOptimizingMemory) return;
    
    final imageCache = PaintingBinding.instance.imageCache;
    
    // Логируем текущее состояние кэша
    if (kDebugMode) {
      Logs().v('[MemoryManager] Cache stats: ${imageCache.currentSize}/${imageCache.maximumSize} images, '
               '${(imageCache.currentSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB/'
               '${(imageCache.maximumSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB');
    }
    
    // Очищаем кэш если превышены лимиты
    if (imageCache.currentSizeBytes > _maxImageCacheSize * 0.8 ||
        imageCache.currentSize > _maxImageCacheCount * 0.8) {
      Logs().i('[MemoryManager] Image cache near limit, clearing...');
      clearImageCache();
    }
    
    // Очищаем глобальные кэши если память заканчивается
    if (isLowMemory) {
      Logs().w('[MemoryManager] Low memory detected, optimizing...');
      optimizeForLowMemory();
    }

    // Очищаем старые кэши каждые 10 минут
    _cleanupAppCaches();
  }
  
  void clearImageCache() {
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      Logs().i('[MemoryManager] Image cache cleared');
    } catch (e) {
      Logs().e('[MemoryManager] Error clearing image cache', e);
    }
  }
  
  void optimizeForLowMemory() {
    if (_isOptimizingMemory) return;
    _isOptimizingMemory = true;
    
    try {
      // Очищаем все кэши
      clearImageCache();
      AppCaches.clearAll();
      
      // Уменьшаем лимиты кэша
      PaintingBinding.instance.imageCache.maximumSize = _maxImageCacheCount ~/ 2;
      PaintingBinding.instance.imageCache.maximumSizeBytes = _maxImageCacheSize ~/ 2;
      
      Logs().i('[MemoryManager] Low memory optimization complete');
      
      // Восстанавливаем лимиты через 5 минут
      Timer(const Duration(minutes: 5), () {
        PaintingBinding.instance.imageCache.maximumSize = _maxImageCacheCount;
        PaintingBinding.instance.imageCache.maximumSizeBytes = _maxImageCacheSize;
        _isOptimizingMemory = false;
      });
      
    } catch (e) {
      Logs().e('[MemoryManager] Error during low memory optimization', e);
      _isOptimizingMemory = false;
    }
  }
  
  void _cleanupAppCaches() {
    // Статистика перед очисткой
    final stats = AppCaches.getStats();
    if (kDebugMode) {
      Logs().v('[MemoryManager] App caches: $stats');
    }
    
    // Периодическая очистка не нужна - кэши сами управляют TTL
  }

  /// Очистка при переходе между экранами
  void onPageChanged() {
    final imageCache = PaintingBinding.instance.imageCache;
    
    // Если кэш изображений переполнен, очищаем часть
    if (imageCache.currentSize > imageCache.maximumSize * 0.7) {
      // Очищаем только неактивные изображения
      imageCache.clearLiveImages();
    }
  }

  /// Принудительная оптимизация памяти
  void forceOptimization() {
    Logs().i('[MemoryManager] Force optimization requested');
    clearImageCache();
    AppCaches.clearAll();
    
    // Принудительный вызов сборщика мусора
    if (kDebugMode) {
      Future.microtask(() => Future.delayed(Duration.zero));
    }
  }

  Map<String, dynamic> getMemoryStats() {
    final imageCache = PaintingBinding.instance.imageCache;
    final appCacheStats = AppCaches.getStats();
    
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'image_cache': {
        'current_size': imageCache.currentSize,
        'maximum_size': imageCache.maximumSize,
        'current_bytes': imageCache.currentSizeBytes,
        'maximum_bytes': imageCache.maximumSizeBytes,
        'usage_percent': (imageCache.currentSize / imageCache.maximumSize * 100).round(),
      },
      'app_caches': appCacheStats,
      'is_low_memory': isLowMemory,
      'is_optimizing': _isOptimizingMemory,
    };
  }
  
  void dispose() {
    _memoryCheckTimer?.cancel();
    AppCaches.disposeAll();
    Logs().i('[MemoryManager] Disposed');
  }
}

/// Extension для удобного использования
extension MemoryManagerExtension on MemoryManager {
  /// Выполняет действие с предварительной проверкой памяти
  Future<T> withMemoryCheck<T>(Future<T> Function() action) async {
    if (isLowMemory) {
      Logs().w('[MemoryManager] Low memory, skipping heavy operation');
      optimizeForLowMemory();
      throw StateError('Low memory - operation skipped');
    }
    return await action();
  }
}
