import 'package:flutter/material.dart';
import 'package:simplemessenger/config/themes.dart';

class MessageSendAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback? onAnimationComplete;
  final bool trigger;

  const MessageSendAnimation({
    super.key,
    required this.child,
    this.onAnimationComplete,
    required this.trigger,
  });

  @override
  State<MessageSendAnimation> createState() => _MessageSendAnimationState();
}

class _MessageSendAnimationState extends State<MessageSendAnimation>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _flyController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _flyAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _flyController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.elasticOut,
    ));

    _flyAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(3.0, -1.5),
    ).animate(CurvedAnimation(
      parent: _flyController,
      curve: Curves.easeInBack,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _flyController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _flyController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    ));

    _flyController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
        _reset();
      }
    });
  }

  @override
  void didUpdateWidget(MessageSendAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _startAnimation();
    }
  }

  void _startAnimation() async {
    await _pulseController.forward();
    await _pulseController.reverse();
    await _flyController.forward();
  }

  void _reset() {
    _pulseController.reset();
    _flyController.reset();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _flyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _flyController]),
      builder: (context, child) {
        return Transform.translate(
          offset: _flyAnimation.value * 100,
          child: Transform.rotate(
            angle: _rotationAnimation.value * 3.14159,
            child: Transform.scale(
              scale: _pulseAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}