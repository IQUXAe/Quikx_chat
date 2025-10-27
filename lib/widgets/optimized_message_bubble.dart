import 'package:flutter/material.dart';

/// Оптимизированный пузырь сообщения с улучшенной анимацией
class OptimizedMessageBubble extends StatefulWidget {
  final Widget child;
  final bool ownMessage;
  final Color color;
  final BorderRadius borderRadius;
  final bool animateIn;
  final VoidCallback? onAnimationComplete;

  const OptimizedMessageBubble({
    super.key,
    required this.child,
    required this.ownMessage,
    required this.color,
    required this.borderRadius,
    this.animateIn = false,
    this.onAnimationComplete,
  });

  @override
  State<OptimizedMessageBubble> createState() => _OptimizedMessageBubbleState();
}

class _OptimizedMessageBubbleState extends State<OptimizedMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Создаем анимации с оптимизированными кривыми
    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ),);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ),);

    _slideAnimation = Tween<Offset>(
      begin: Offset(widget.ownMessage ? 0.3 : -0.3, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutQuart),
    ),);

    // Запускаем анимацию если нужно
    if (widget.animateIn) {
      _controller.forward().then((_) {
        widget.onAnimationComplete?.call();
      });
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(OptimizedMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.animateIn && !oldWidget.animateIn) {
      _controller.reset();
      _controller.forward().then((_) {
        widget.onAnimationComplete?.call();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: widget.borderRadius,
                  boxShadow: widget.animateIn && _controller.isAnimating
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1 * _fadeAnimation.value),
                            blurRadius: 8.0 * _scaleAnimation.value,
                            offset: Offset(0, 4 * _scaleAnimation.value),
                          ),
                        ]
                      : null,
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

/// Простая версия без анимации для производительности
class SimpleMessageBubble extends StatelessWidget {
  final Widget child;
  final Color color;
  final BorderRadius borderRadius;
  final EdgeInsets padding;

  const SimpleMessageBubble({
    super.key,
    required this.child,
    required this.color,
    required this.borderRadius,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }
}

/// Анимированная индикация набора текста
class TypingIndicatorBubble extends StatefulWidget {
  final Color color;
  final BorderRadius borderRadius;

  const TypingIndicatorBubble({
    super.key,
    required this.color,
    required this.borderRadius,
  });

  @override
  State<TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<TypingIndicatorBubble>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Создаем анимации для трех точек с задержкой
    _animations = List.generate(3, (index) {
      return Tween<double>(
        begin: 0.4,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(
          index * 0.2,
          0.6 + index * 0.2,
          curve: Curves.easeInOut,
        ),
      ),);
    });

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: widget.borderRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Opacity(
                opacity: _animations[index].value,
                child: Container(
                  width: 6,
                  height: 6,
                  margin: EdgeInsets.only(
                    right: index < 2 ? 4 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
