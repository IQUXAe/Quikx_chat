import 'package:flutter/painting.dart';

class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._();
  factory ImageCacheManager() => _instance;
  ImageCacheManager._();
  
  void configure() {
    final imageCache = PaintingBinding.instance.imageCache;
    
    // Увеличиваем лимиты кэша для лучшей производительности
    imageCache.maximumSize = 200; // было 100
    imageCache.maximumSizeBytes = 100 * 1024 * 1024; // 100MB вместо 50MB
  }
  
  void clearIfNeeded() {
    final imageCache = PaintingBinding.instance.imageCache;
    
    // Очищаем если превышен лимит
    if (imageCache.currentSizeBytes > imageCache.maximumSizeBytes * 0.9) {
      imageCache.clear();
    }
  }
}
