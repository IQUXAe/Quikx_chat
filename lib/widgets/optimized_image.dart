import 'package:flutter/material.dart';
import 'package:simplemessenger/utils/memory_manager.dart';

class OptimizedNetworkImage extends StatefulWidget {
  final String imageUrl;
  final Widget? placeholder;
  final Widget? errorWidget;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const OptimizedNetworkImage({
    super.key,
    required this.imageUrl,
    this.placeholder,
    this.errorWidget,
    this.width,
    this.height,
    this.fit,
  });

  @override
  State<OptimizedNetworkImage> createState() => _OptimizedNetworkImageState();
}

class _OptimizedNetworkImageState extends State<OptimizedNetworkImage> {
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Image.network(
        widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            // Проверяем память после загрузки изображения
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (MemoryManager().isLowMemory) {
                MemoryManager().optimizeForLowMemory();
              }
            });
            return child;
          }
          return widget.placeholder ?? 
            SizedBox(
              width: widget.width ?? 50,
              height: widget.height ?? 50,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
        },
        errorBuilder: (context, error, stackTrace) {
          return widget.errorWidget ?? 
            Container(
              width: widget.width ?? 50,
              height: widget.height ?? 50,
              color: Colors.grey[300],
              child: const Icon(Icons.error_outline, color: Colors.grey),
            );
        },
      ),
    );
  }
}

class LazyLoadingImage extends StatefulWidget {
  final String imageUrl;
  final Widget placeholder;
  final double? width;
  final double? height;

  const LazyLoadingImage({
    super.key,
    required this.imageUrl,
    required this.placeholder,
    this.width,
    this.height,
  });

  @override
  State<LazyLoadingImage> createState() => _LazyLoadingImageState();
}

class _LazyLoadingImageState extends State<LazyLoadingImage> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.imageUrl),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.1 && !_isVisible) {
          setState(() => _isVisible = true);
        }
      },
      child: _isVisible
          ? OptimizedNetworkImage(
              imageUrl: widget.imageUrl,
              width: widget.width,
              height: widget.height,
              placeholder: widget.placeholder,
            )
          : widget.placeholder,
    );
  }
}

// Простая реализация VisibilityDetector для демонстрации
class VisibilityDetector extends StatefulWidget {
  final Key key;
  final Widget child;
  final Function(VisibilityInfo) onVisibilityChanged;

  const VisibilityDetector({
    required this.key,
    required this.child,
    required this.onVisibilityChanged,
  }) : super(key: key);

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onVisibilityChanged(VisibilityInfo(visibleFraction: 1.0));
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class VisibilityInfo {
  final double visibleFraction;
  
  VisibilityInfo({required this.visibleFraction});
}