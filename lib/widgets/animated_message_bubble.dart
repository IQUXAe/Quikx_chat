import 'package:flutter/material.dart';
import 'package:simplemessenger/config/themes.dart';

class AnimatedMessageBubble extends StatefulWidget {
  final Widget child;
  final bool isOwn;
  final int index;

  const AnimatedMessageBubble({
    super.key,
    required this.child,
    required this.isOwn,
    required this.index,
  });

  @override
  State<AnimatedMessageBubble> createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<AnimatedMessageBubble>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: Duration(
        milliseconds: 300 + (widget.index * 50).clamp(0, 200),
      ),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: SimpleMessengerThemes.fastAnimationDuration,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(widget.isOwn ? 0.3 : -0.3, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: SimpleMessengerThemes.bounceAnimationCurve,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: SimpleMessengerThemes.bounceAnimationCurve,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    // Запускаем анимацию с небольшой задержкой
    Future.delayed(Duration(milliseconds: widget.index * 30), () {
      if (mounted) {
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}