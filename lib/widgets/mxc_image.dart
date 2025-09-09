import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'package:simplemessenger/config/themes.dart';
import 'package:simplemessenger/utils/client_download_content_extension.dart';
import 'package:simplemessenger/utils/matrix_sdk_extensions/matrix_file_extension.dart';
import 'package:simplemessenger/utils/global_cache.dart';
import 'package:simplemessenger/widgets/matrix.dart';

class MxcImage extends StatefulWidget {
  final Uri? uri;
  final Event? event;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final bool isThumbnail;
  final bool animated;
  final Duration retryDuration;
  final Duration animationDuration;
  final Curve animationCurve;
  final ThumbnailMethod thumbnailMethod;
  final Widget Function(BuildContext context)? placeholder;
  final String? cacheKey;
  final Client? client;
  final BorderRadius borderRadius;
  final bool preloadImage;

  const MxcImage({
    this.uri,
    this.event,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.isThumbnail = true,
    this.animated = false,
    this.animationDuration = SimpleMessengerThemes.animationDuration,
    this.retryDuration = const Duration(seconds: 2),
    this.animationCurve = SimpleMessengerThemes.animationCurve,
    this.thumbnailMethod = ThumbnailMethod.scale,
    this.cacheKey,
    this.client,
    this.borderRadius = BorderRadius.zero,
    this.preloadImage = false,
    super.key,
  });

  @override
  State<MxcImage> createState() => _MxcImageState();
}

class _MxcImageState extends State<MxcImage> {
  static final Map<String, Future<Uint8List?>> _loadingCache = {};
  final GlobalCache _globalCache = GlobalCache();
  Uint8List? _imageDataNoCache;
  bool _isLoading = false;

  String? get _globalCacheKey {
    if (widget.uri != null) {
      return '${widget.uri}_${widget.width}_${widget.height}_${widget.isThumbnail}';
    }
    if (widget.event != null) {
      return '${widget.event!.eventId}_${widget.isThumbnail}';
    }
    return null;
  }

  Uint8List? get _imageData {
    final globalKey = _globalCacheKey;
    if (globalKey != null) {
      final cached = _globalCache.getImage(globalKey);
      if (cached != null) return cached;
    }
    
    return widget.cacheKey == null
        ? _imageDataNoCache
        : _globalCache.getImage(widget.cacheKey!);
  }

  set _imageData(Uint8List? data) {
    if (data == null) return;
    
    final globalKey = _globalCacheKey;
    if (globalKey != null) {
      _globalCache.cacheImage(globalKey, data);
    }
    
    final cacheKey = widget.cacheKey;
    if (cacheKey == null) {
      _imageDataNoCache = data;
    } else {
      _globalCache.cacheImage(cacheKey, data);
    }
  }

  Future<Uint8List?> _load() async {
    if (!mounted) return null;
    final client =
        widget.client ?? widget.event?.room.client ?? Matrix.of(context).client;
    final uri = widget.uri;
    final event = widget.event;

    if (uri != null) {
      final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
      final width = widget.width;
      final realWidth = width == null ? null : width * devicePixelRatio;
      final height = widget.height;
      final realHeight = height == null ? null : height * devicePixelRatio;

      final remoteData = await client.downloadMxcCached(
        uri,
        width: realWidth,
        height: realHeight,
        thumbnailMethod: widget.thumbnailMethod,
        isThumbnail: widget.isThumbnail,
        animated: widget.animated,
      );
      return remoteData;
    }

    if (event != null) {
      final data = await event.downloadAndDecryptAttachment(
        getThumbnail: widget.isThumbnail,
      );
      if (data.detectFileType is MatrixImageFile || widget.isThumbnail) {
        return data.bytes;
      }
    }
    return null;
  }

  void _tryLoad() async {
    if (_imageData != null || _isLoading) {
      return;
    }

    final cacheKey = _globalCacheKey ?? widget.cacheKey;
    if (cacheKey != null && _loadingCache.containsKey(cacheKey)) {
      // Wait for existing load operation
      final data = await _loadingCache[cacheKey];
      if (mounted && data != null) {
        setState(() {
          _imageData = data;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final loadFuture = _load();
      if (cacheKey != null) {
        _loadingCache[cacheKey] = loadFuture;
      }

      final data = await loadFuture;
      
      if (cacheKey != null) {
        _loadingCache.remove(cacheKey);
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (data != null) {
          _imageData = data;
        }
      });
    } on IOException catch (_) {
      if (cacheKey != null) {
        _loadingCache.remove(cacheKey);
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      await Future.delayed(widget.retryDuration);
      _tryLoad();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.preloadImage) {
      _tryLoad();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryLoad());
    }
  }

  Widget placeholder(BuildContext context) =>
      widget.placeholder?.call(context) ??
      Container(
        width: widget.width,
        height: widget.height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: widget.borderRadius,
        ),
        child: _isLoading
            ? const CircularProgressIndicator.adaptive(strokeWidth: 2)
            : Icon(
                Icons.image_outlined,
                size: min(widget.height ?? 64, 64),
                color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
              ),
      );

  @override
  Widget build(BuildContext context) {
    final data = _imageData;
    final hasData = data != null && data.isNotEmpty;

    if (hasData) {
      return AnimatedSwitcher(
        duration: widget.animationDuration,
        child: ClipRRect(
          borderRadius: widget.borderRadius,
          child: Image.memory(
            data,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            filterQuality: widget.isThumbnail
                ? FilterQuality.low
                : FilterQuality.medium,
            errorBuilder: (context, e, s) {
              Logs().d('Unable to render mxc image', e, s);
              return SizedBox(
                width: widget.width,
                height: widget.height,
                child: Material(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: min(widget.height ?? 64, 64),
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
    
    return placeholder(context);
  }
}