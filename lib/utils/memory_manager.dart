import 'dart:async';
import 'dart:io';
import 'package:flutter/painting.dart';

class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  static const int _lowMemoryThreshold = 100 * 1024 * 1024; // 100MB
  static const int _maxImageCacheSize = 50 * 1024 * 1024; // 50MB
  static const int _maxImageCacheCount = 100;
  
  Timer? _memoryCheckTimer;
  
  void initialize() {
    // Настраиваем лимиты кэша изображений
    PaintingBinding.instance.imageCache.maximumSize = _maxImageCacheCount;
    PaintingBinding.instance.imageCache.maximumSizeBytes = _maxImageCacheSize;
    
    // Запускаем периодическую проверку памяти
    _memoryCheckTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _checkAndOptimizeMemory();
    });
  }
  
  bool get isLowMemory {
    if (Platform.isIOS) return false;
    
    try {
      return ProcessInfo.currentRss > _lowMemoryThreshold * 4;
    } catch (e) {
      return false;
    }
  }
  
  void _checkAndOptimizeMemory() {
    final imageCache = PaintingBinding.instance.imageCache;
    
    // Очищаем кэш если превышены лимиты
    if (imageCache.currentSizeBytes > _maxImageCacheSize * 0.8 ||
        imageCache.currentSize > _maxImageCacheCount * 0.8) {
      clearImageCache();
    }
    
    if (isLowMemory) {
      optimizeForLowMemory();
    }
  }
  
  void clearImageCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }
  
  void optimizeForLowMemory() {
    clearImageCache();
    // Принудительно запускаем сборку мусора через Future.microtask
    Future.microtask(() {});
  }
  
  void dispose() {
    _memoryCheckTimer?.cancel();
  }
}