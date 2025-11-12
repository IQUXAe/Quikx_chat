import 'package:flutter/material.dart';
import 'package:quikxchat/config/app_config.dart';

/// Централизованный класс для всех тематических констант приложения
abstract class AppThemeConstants {
  // Цвета
  static const Color primaryColor = AppConfig.primaryColor;
  static const Color primaryColorLight = AppConfig.primaryColorLight;
  static const Color secondaryColor = AppConfig.secondaryColor;
  static const Color chatColor = AppConfig.chatColor;

  // Радиусы скругления
  static const double smallBorderRadius = 8.0;
  static const double mediumBorderRadius = 12.0;
  static const double largeBorderRadius = 16.0;
  static const double extraLargeBorderRadius = 24.0;
  static const double defaultBorderRadius = AppConfig.borderRadius; // 16.0
  
  // Отступы
  static const double smallPadding = 8.0;
  static const double mediumPadding = 16.0;
  static const double largePadding = 24.0;
  static const double extraLargePadding = 32.0;
  
  // Размеры иконок
  static const double smallIconSize = 16.0;
  static const double mediumIconSize = 24.0;
  static const double largeIconSize = 32.0;
  static const double extraLargeIconSize = 48.0;
  
  // Размеры аватаров
  static const double smallAvatarSize = 32.0;
  static const double mediumAvatarSize = 40.0;
  static const double largeAvatarSize = 64.0;
  static const double extraLargeAvatarSize = 96.0;
  
  // Размеры элементов интерфейса
  static const double defaultButtonHeight = 48.0;
  static const double smallButtonHeight = 36.0;
  static const double largeButtonHeight = 56.0;
  
  static const double defaultInputHeight = 48.0;
  static const double smallInputHeight = 40.0;
  static const double largeInputHeight = 56.0;
  
  static const double listItemHeight = 64.0;
  static const double chatListItemHeight = 80.0;
  
  // Размеры шрифтов
  static const double smallFontSize = 12.0;
  static const double defaultFontSize = 14.0;
  static const double mediumFontSize = 16.0;
  static const double largeFontSize = 18.0;
  static const double extraLargeFontSize = 24.0;
  static const double messageFontSize = AppConfig.messageFontSize; // 15.0
  
  // Длительности анимаций
  static const Duration quickAnimationDuration = Duration(milliseconds: 150);
  static const Duration shortAnimationDuration = Duration(milliseconds: 250);
  static const Duration standardAnimationDuration = Duration(milliseconds: 300);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  static const Duration slowAnimationDuration = Duration(milliseconds: 550);
  static const Duration verySlowAnimationDuration = Duration(milliseconds: 700);
  
  // Кривые анимаций
  static const Curve standardCurve = Curves.easeInOut;
  static const Curve fastCurve = Curves.easeOutQuart;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve slideCurve = Curves.easeInOutCubic;
  static const Curve smoothCurve = Curves.fastOutSlowIn;
  
  // Размеры макета
  static const double columnWidth = 420.0;
  static const double maxTimelineWidth = columnWidth * 2;
  static const double navRailWidth = 90.0;
  
  // Прочие размеры
  static const double dividerThickness = 1.0;
  static const double borderWidth = 1.0;
  static const double elevationLow = 1.0;
  static const double elevationMedium = 2.0;
  static const double elevationHigh = 4.0;
}

/// Расширения для упрощения доступа к константам темы
extension ThemeExtension on BuildContext {
  /// Получить цвета темы
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  
  /// Получить текстовые стили темы
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  /// Проверить, используется ли темная тема
  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;
  
  /// Получить размеры для адаптивного интерфейса
  bool get isLargeScreen => MediaQuery.sizeOf(this).width > AppThemeConstants.columnWidth * 2;
  
  bool get isMediumScreen => MediaQuery.sizeOf(this).width > AppThemeConstants.columnWidth;
  
  bool get isSmallScreen => MediaQuery.sizeOf(this).width <= AppThemeConstants.columnWidth;
}

/// Централизованные стили для часто используемых элементов
abstract class AppWidgetStyles {
  // Кнопки
  static ButtonStyle primaryButtonStyle(ColorScheme colorScheme) => ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppThemeConstants.mediumPadding,
          vertical: AppThemeConstants.smallPadding + 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppThemeConstants.mediumBorderRadius),
        ),
        textStyle: TextStyle(
          fontSize: AppThemeConstants.defaultFontSize,
          fontWeight: FontWeight.w600,
        ),
      );

  static ButtonStyle outlinedButtonStyle(ColorScheme colorScheme) => OutlinedButton.styleFrom(
        side: BorderSide(
          width: 1.5,
          color: colorScheme.primary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppThemeConstants.mediumBorderRadius),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppThemeConstants.mediumPadding,
          vertical: AppThemeConstants.smallPadding + 2,
        ),
        textStyle: TextStyle(
          fontSize: AppThemeConstants.defaultFontSize,
          fontWeight: FontWeight.w600,
        ),
      );

  static ButtonStyle textButtonStyle(ColorScheme colorScheme) => TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        textStyle: TextStyle(
          fontSize: AppThemeConstants.defaultFontSize,
          fontWeight: FontWeight.w600,
        ),
      );

  // Card
  static CardThemeData cardTheme(ColorScheme colorScheme) => CardThemeData(
        elevation: AppThemeConstants.elevationMedium,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppThemeConstants.mediumBorderRadius),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
            width: AppThemeConstants.borderWidth,
          ),
        ),
        color: colorScheme.surfaceContainerLow,
      );

  // Input
  static InputDecorationTheme inputDecorationTheme(ColorScheme colorScheme) => InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeConstants.mediumBorderRadius),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: AppThemeConstants.borderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeConstants.mediumBorderRadius),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: AppThemeConstants.borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeConstants.mediumBorderRadius),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppThemeConstants.mediumPadding,
          vertical: AppThemeConstants.smallPadding + 2,
        ),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          fontSize: AppThemeConstants.defaultFontSize,
        ),
      );
}