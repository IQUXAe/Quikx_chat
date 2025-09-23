import 'package:flutter/material.dart';
import 'package:quikxchat/config/themes.dart';

class AnimatedDialog extends StatefulWidget {
  final Widget child;
  final bool barrierDismissible;

  const AnimatedDialog({
    super.key,
    required this.child,
    this.barrierDismissible = true,
  });

  @override
  State<AnimatedDialog> createState() => _AnimatedDialogState();

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: QuikxChatThemes.animationDuration,
      pageBuilder: (context, animation, secondaryAnimation) {
        return AnimatedDialog(
          barrierDismissible: barrierDismissible,
          child: child,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.8,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: QuikxChatThemes.bounceAnimationCurve,
            ),),
            child: child,
          ),
        );
      },
    );
  }
}

class _AnimatedDialogState extends State<AnimatedDialog>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: QuikxChatThemes.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: QuikxChatThemes.bounceAnimationCurve,
    ),);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ),);

    _controller.forward();
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
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}