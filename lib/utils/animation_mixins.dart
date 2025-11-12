import 'package:flutter/widgets.dart';

/// Миксин для базового управления AnimationController
mixin AnimationControllerMixin<T extends StatefulWidget> on State<T> {
  final List<AnimationController> _animationControllers = [];

  /// Создать и отслеживать AnimationController
  AnimationController createAnimationController({
    required TickerProvider vsync,
    Duration duration = const Duration(milliseconds: 300),
    String? debugLabel,
  }) {
    final controller = AnimationController(
      duration: duration,
      vsync: vsync,
      debugLabel: debugLabel,
    );
    _animationControllers.add(controller);
    return controller;
  }

  /// Освободить все AnimationController
  void disposeAnimationControllers() {
    for (final controller in _animationControllers) {
      if (!controller.isCompleted && !controller.isDismissed) {
        controller.dispose();
      }
    }
    _animationControllers.clear();
  }
  
  /// Метод для вызова в dispose родительского State
  void disposeWithAnimations() {
    disposeAnimationControllers();
  }
}

/// Миксин для создания стандартных анимаций (Scale, Fade, Slide)
mixin StandardAnimationMixin<T extends StatefulWidget> on State<T> {
  /// Создать анимацию масштабирования
  Animation<double> createScaleAnimation({
    required AnimationController controller,
    double begin = 0.8,
    double end = 1.0,
    Curve curve = Curves.easeInOut,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// Создать анимацию прозрачности
  Animation<double> createFadeAnimation({
    required AnimationController controller,
    double begin = 0.0,
    double end = 1.0,
    Curve curve = Curves.easeInOut,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// Создать анимацию слайда
  Animation<Offset> createSlideAnimation({
    required AnimationController controller,
    Offset begin = const Offset(0.0, 0.1),
    Offset end = Offset.zero,
    Curve curve = Curves.easeInOut,
  }) {
    return Tween<Offset>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }
}

/// Миксин для повторяющихся анимаций (например, индикаторы загрузки)
mixin RepeatingAnimationMixin<T extends StatefulWidget> on State<T> {
  /// Запустить повторяющуюся анимацию
  void startRepeatingAnimation(
    AnimationController controller, {
    Duration? period,
  }) {
    controller.repeat(period: period);
  }

  /// Остановить повторяющуюся анимацию
  void stopRepeatingAnimation(AnimationController controller) {
    controller.stop();
  }
}

/// Пример использования миксинов в State классе:
/// class _MyWidgetState extends State<MyWidget>
///    with TickerProviderStateMixin, AnimationControllerMixin, StandardAnimationMixin {
///  @override
///  void dispose() {
///    disposeWithAnimations(); // Вызываем для очистки контроллеров
///    super.dispose();
///  }
///}