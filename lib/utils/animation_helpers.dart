import 'package:flutter/animation.dart';

/// Общий класс для анимационных констант и хелперов
class AnimationHelpers {
  /// Стандартная длительность анимации
  static const Duration standardDuration = Duration(milliseconds: 300);
  
  /// Длительность быстрой анимации
  static const Duration quickDuration = Duration(milliseconds: 150);
  
  /// Длительность медленной анимации
  static const Duration slowDuration = Duration(milliseconds: 500);
  
  /// Длительность очень медленной анимации (для сложных переходов)
  static const Duration verySlowDuration = Duration(milliseconds: 700);
  
  /// Длительность анимации с физикой (для привлекательных эффектов)
  static const Duration physicsDuration = Duration(milliseconds: 500);
  
  /// Стандартная кривая анимации
  static const Curve standardCurve = Curves.easeInOut;
  
  /// Кривая анимации с упругостью
  static const Curve elasticCurve = Curves.elasticOut;
  
  /// Кривая анимации с отскоком
  static const Curve bounceCurve = Curves.bounceOut;
  
  /// Кривая анимации для привлекательных переходов
  static const Curve attractiveCurve = Curves.elasticOut;
  
  /// Кривая анимации для плавных переходов
  static const Curve smoothCurve = Curves.fastOutSlowIn;
  
  /// Кривая анимации для быстрых откликов
  static const Curve responsiveCurve = Curves.linear;
}

/// Общий класс для часто используемых отступов и размеров
class SpacingHelpers {
  /// Маленький отступ
  static const double small = 8.0;
  
  /// Стандартный отступ
  static const double medium = 16.0;
  
  /// Большой отступ
  static const double large = 24.0;
  
  /// Очень большой отступ
  static const double extraLarge = 32.0;
  
  /// Маленький радиус скругления
  static const double smallRadius = 8.0;
  
  /// Стандартный радиус скругления
  static const double mediumRadius = 12.0;
  
  /// Большой радиус скругления
  static const double largeRadius = 16.0;
  
  /// Размер маленькой иконки
  static const double smallIconSize = 16.0;
  
  /// Размер стандартной иконки
  static const double mediumIconSize = 24.0;
  
  /// Размер большой иконки
  static const double largeIconSize = 32.0;
  
  /// Стандартный размер аватара
  static const double avatarSize = 40.0;
  
  /// Размер большого аватара
  static const double largeAvatarSize = 64.0;
  
  /// Размер маленького аватара
  static const double smallAvatarSize = 32.0;
}