import 'package:flutter/material.dart';
import 'package:simplemessenger/config/themes.dart';

class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const AnimatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rippleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;
  
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: SimpleMessengerThemes.fastAnimationDuration,
      vsync: this,
    );
    
    _rippleController = AnimationController(
      duration: SimpleMessengerThemes.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: SimpleMessengerThemes.fastAnimationCurve,
    ));

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _scaleController.forward();
    _rippleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _scaleController.reverse();
    _rippleController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
    _rippleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleController, _rippleController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: widget.onPressed != null ? _onTapDown : null,
            onTapUp: widget.onPressed != null ? _onTapUp : null,
            onTapCancel: widget.onPressed != null ? _onTapCancel : null,
            onTap: widget.onPressed,
            child: Container(
              padding: widget.padding ?? const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? theme.colorScheme.primary,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (widget.backgroundColor ?? theme.colorScheme.primary)
                        .withOpacity(0.3 * _rippleAnimation.value),
                    blurRadius: 8 * _rippleAnimation.value,
                    spreadRadius: 2 * _rippleAnimation.value,
                  ),
                ],
              ),
              child: DefaultTextStyle(
                style: TextStyle(
                  color: widget.foregroundColor ?? theme.colorScheme.onPrimary,
                ),
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}