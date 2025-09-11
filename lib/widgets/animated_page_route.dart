import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

class ModernPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final TransitionType transitionType;
  final bool isModal;

  ModernPageRoute({
    required this.child,
    this.transitionType = TransitionType.slideHorizontal,
    this.isModal = false,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildTransition(
              context,
              animation,
              secondaryAnimation,
              child,
              transitionType,
              isModal,
            );
          },
        );

  static Widget _buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
    TransitionType type,
    bool isModal,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: const Cubic(0.25, 0.1, 0.25, 1.0),
    );
    
    final reverseCurvedAnimation = CurvedAnimation(
      parent: secondaryAnimation,
      curve: const Cubic(0.4, 0.0, 0.2, 1.0),
    );

    switch (type) {
      case TransitionType.slideHorizontal:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
            ),),
            child: child,
          ),
        );

      case TransitionType.slideVertical:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
            ),),
            child: child,
          ),
        );

      case TransitionType.sharedAxis:
        return SharedAxisTransition(
          animation: curvedAnimation,
          secondaryAnimation: reverseCurvedAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
          child: child,
        );

      case TransitionType.fadeThrough:
        return FadeThroughTransition(
          animation: curvedAnimation,
          secondaryAnimation: reverseCurvedAnimation,
          child: child,
        );

      case TransitionType.container:
        return isModal
            ? FadeScaleTransition(
                animation: curvedAnimation,
                child: child,
              )
            : SharedAxisTransition(
                animation: curvedAnimation,
                secondaryAnimation: reverseCurvedAnimation,
                transitionType: SharedAxisTransitionType.scaled,
                child: child,
              );

      case TransitionType.scaleRotate:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.85,
            end: 1.0,
          ).animate(curvedAnimation),
          child: RotationTransition(
            turns: Tween<double>(
              begin: 0.02,
              end: 0.0,
            ).animate(curvedAnimation),
            child: FadeTransition(
              opacity: curvedAnimation,
              child: child,
            ),
          ),
        );
    }
  }
}

class ModernPage<T> extends Page<T> {
  final Widget child;
  final TransitionType transitionType;
  final bool isModal;

  const ModernPage({
    required this.child,
    this.transitionType = TransitionType.slideHorizontal,
    this.isModal = false,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    return ModernPageRoute<T>(
      child: child,
      transitionType: transitionType,
      isModal: isModal,
      settings: this,
    );
  }
}

enum TransitionType {
  slideHorizontal,
  slideVertical,
  sharedAxis,
  fadeThrough,
  container,
  scaleRotate,
}