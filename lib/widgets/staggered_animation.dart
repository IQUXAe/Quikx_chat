import 'package:flutter/material.dart';
import 'package:quikxchat/config/themes.dart';

class StaggeredAnimation extends StatefulWidget {
  final List<Widget> children;
  final Duration delay;
  final Axis direction;

  const StaggeredAnimation({
    super.key,
    required this.children,
    this.delay = const Duration(milliseconds: 100),
    this.direction = Axis.vertical,
  });

  @override
  State<StaggeredAnimation> createState() => _StaggeredAnimationState();
}

class _StaggeredAnimationState extends State<StaggeredAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    
    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        duration: QuikxChatThemes.animationDuration,
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) =>
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: QuikxChatThemes.bounceAnimationCurve,
        ),
      ),
    ).toList();

    _startAnimations();
  }

  void _startAnimations() {
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(widget.delay * i, () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        widget.children.length,
        (index) => AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            final slideOffset = widget.direction == Axis.vertical
                ? Offset(0, (1 - _animations[index].value) * 50)
                : Offset((1 - _animations[index].value) * 50, 0);

            return Transform.translate(
              offset: slideOffset,
              child: Opacity(
                opacity: _animations[index].value,
                child: Transform.scale(
                  scale: 0.8 + (_animations[index].value * 0.2),
                  child: widget.children[index],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}