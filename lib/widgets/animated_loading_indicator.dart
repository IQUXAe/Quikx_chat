import 'package:flutter/material.dart';
import 'package:simplemessenger/config/themes.dart';

class AnimatedLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;

  const AnimatedLoadingIndicator({
    super.key,
    this.size = 24.0,
    this.color,
  });

  @override
  State<AnimatedLoadingIndicator> createState() => _AnimatedLoadingIndicatorState();
}

class _AnimatedLoadingIndicatorState extends State<AnimatedLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _scaleController = AnimationController(
      duration: SimpleMessengerThemes.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: SimpleMessengerThemes.bounceAnimationCurve,
    ));

    _scaleController.forward();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: RotationTransition(
        turns: _rotationController,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                widget.color ?? theme.colorScheme.primary,
                (widget.color ?? theme.colorScheme.primary).withOpacity(0.3),
              ],
              stops: const [0.0, 1.0],
            ),
          ),
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.color ?? theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}