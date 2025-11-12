import 'dart:async';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

/// Улучшенная система предварительной загрузки изображений с батчингом и кэшированием
class OptimizedImagePreloader {
  static final OptimizedImagePreloader _instance = OptimizedImagePreloader._internal();
  factory OptimizedImagePreloader() => _instance;
  OptimizedImagePreloader._internal();

  final Map<String, Completer<void>> _pendingPreloads = {};
  final Set<String> _preloadedImages = {};

  /// Предварительно загрузить изображение с URL используя контекст
  Future<void> preloadImage(BuildContext context, String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty || _preloadedImages.contains(imageUrl)) {
      return Future.value();
    }

    // Если уже есть ожидающий preload для этого URL, возвращаем его Future
    if (_pendingPreloads.containsKey(imageUrl)) {
      return _pendingPreloads[imageUrl]!.future;
    }

    final completer = Completer<void>();
    _pendingPreloads[imageUrl] = completer;

    try {
      final imageProvider = _getImageProvider(imageUrl);
      if (imageProvider != null) {
        await precacheImage(imageProvider, context);
        _preloadedImages.add(imageUrl);
      }
      completer.complete();
    } catch (e) {
      completer.completeError(e);
    } finally {
      _pendingPreloads.remove(imageUrl);
    }
  }

  /// Батчевая предварительная загрузка нескольких изображений
  Future<void> preloadImagesBatch(BuildContext context, List<String?> imageUrls) async {
    final validUrls = imageUrls.where((url) => url != null && url.isNotEmpty && !_preloadedImages.contains(url)).cast<String>();
    if (validUrls.isEmpty) return;

    final futures = validUrls.map((url) => preloadImage(context, url)).toList();
    await Future.wait(futures, eagerError: false);
  }

  /// Очистить кэш предварительной загрузки
  void clearCache() {
    _preloadedImages.clear();
    _pendingPreloads.clear();
  }

  /// Проверить, загружено ли изображение
  bool isPreloaded(String imageUrl) => _preloadedImages.contains(imageUrl);

  ImageProvider? _getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return NetworkImage(imageUrl);
    } else if (imageUrl.startsWith('asset:')) {
      return AssetImage(imageUrl.substring(6));
    } else if (imageUrl.startsWith('mxc://')) {
      // MXC URL не может быть обработан без клиента
      return null;
    }
    return null;
  }
}

/// Контекст для предварительной загрузки
extension PreloadContext on Client {
  /// Получить URL для загрузки MXC ресурса
  String getDownloadUrl(Uri? mxc) {
    if (mxc == null) return '';
    return '${homeserver}/_matrix/media/r0/download/${mxc.host}/${mxc.pathSegments.join('/')}';
  }

  /// Предварительно загрузить аватар комнаты
  Future<void> preloadRoomAvatar(BuildContext context, Room room) async {
    if (room.avatar != null) {
      final url = getDownloadUrl(room.avatar);
      await OptimizedImagePreloader().preloadImage(context, url);
    }
  }

  /// Предварительно загрузить аватар пользователя
  Future<void> preloadUserAvatar(BuildContext context, User user) async {
    if (user.avatarUrl != null) {
      final url = getDownloadUrl(user.avatarUrl);
      await OptimizedImagePreloader().preloadImage(context, url);
    }
  }
}