import 'dart:io';
import 'package:flutter/painting.dart';

class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  static const int _lowMemoryThreshold = 100 * 1024 * 1024; // 100MB
  
  bool get isLowMemory {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    
    try {
      // Простая эвристика для определения нехватки памяти
      return ProcessInfo.currentRss > _lowMemoryThreshold * 4;
    } catch (e) {
      return false;
    }
  }
  
  void clearImageCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }
  
  void optimizeForLowMemory() {
    if (isLowMemory) {
      clearImageCache();
      // Force garbage collection
      // System.gc() not available in Dart
    }
  }
}