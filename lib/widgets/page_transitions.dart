import 'package:flutter/material.dart';
import 'package:quikxchat/config/themes.dart';

class PageTransitions {
  static Route<T> slideFromRight<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: QuikxChatThemes.animationDuration,
      reverseTransitionDuration: QuikxChatThemes.animationDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: QuikxChatThemes.slideAnimationCurve,
          ),),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.3, 0.0),
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: QuikxChatThemes.slideAnimationCurve,
            ),),
            child: child,
          ),
        );
      },
    );
  }

  static Route<T> fadeScale<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: QuikxChatThemes.animationDuration,
      reverseTransitionDuration: QuikxChatThemes.animationDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
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

  static Route<T> slideFromBottom<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: QuikxChatThemes.animationDuration,
      reverseTransitionDuration: QuikxChatThemes.animationDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: QuikxChatThemes.slideAnimationCurve,
          ),),
          child: child,
        );
      },
    );
  }
}