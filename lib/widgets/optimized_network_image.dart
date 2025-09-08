import 'package:flutter/material.dart';

class OptimizedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const OptimizedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: width?.round(),
      cacheHeight: height?.round(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? 
          Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / 
                    loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? 
          Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Icon(Icons.error, color: Colors.grey),
          );
      },
    );
  }
}