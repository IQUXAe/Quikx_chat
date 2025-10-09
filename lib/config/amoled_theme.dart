import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'themes.dart';

/// AMOLED тема для экономии батареи на OLED экранах
abstract class AmoledTheme {
  static const Color pureBlack = Color(0xFF000000);
  static const Color darkGray = Color(0xFF0A0A0A);
  static const Color lightGray = Color(0xFF1A1A1A);
  
  /// Создает AMOLED тему с глубоким черным цветом
  static ThemeData buildAmoledTheme(
    BuildContext context, {
    Color? seedColor,
  }) {
    final primaryColor = seedColor ?? const Color(0xFF3B82F6);
    
    final colorScheme = ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: primaryColor,
      // AMOLED специфичные цвета
      surface: pureBlack,
      onSurface: Colors.white,
      background: pureBlack,
      onBackground: Colors.white,
      surfaceVariant: darkGray,
      onSurfaceVariant: Colors.white70,
      // Контейнеры
      primaryContainer: lightGray,
      onPrimaryContainer: Colors.white,
      secondaryContainer: darkGray,
      onSecondaryContainer: Colors.white70,
      tertiaryContainer: lightGray,
      onTertiaryContainer: Colors.white70,
      // Специальные поверхности
      surfaceContainerLowest: pureBlack,
      surfaceContainerLow: darkGray,
      surfaceContainer: lightGray,
      surfaceContainerHigh: Color(0xFF2A2A2A),
      surfaceContainerHighest: Color(0xFF3A3A3A),
    );

    final isColumnMode = QuikxChatThemes.isColumnMode(context);

    return ThemeData(
      visualDensity: VisualDensity.comfortable,
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      
      // Чистый черный фон
      scaffoldBackgroundColor: pureBlack,
      canvasColor: pureBlack,
      
      // Делители
      dividerColor: Colors.white.withOpacity(0.08),
      
      // AppBar
      appBarTheme: AppBarTheme(
        toolbarHeight: isColumnMode ? 72 : 56,
        elevation: 0,
        backgroundColor: pureBlack,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: pureBlack,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),

      // Кнопки
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightGray,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Карточки
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkGray,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),

      // Поля ввода
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: primaryColor,
            width: 2,
          ),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white38),
      ),

      // Снэкбары
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightGray,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Меню
      popupMenuTheme: PopupMenuThemeData(
        color: lightGray,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        textStyle: const TextStyle(color: Colors.white),
      ),

      // Диалоги
      dialogTheme: DialogThemeData(
        backgroundColor: lightGray,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: Colors.white70,
          fontSize: 16,
        ),
      ),

      // Навигационная панель
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: pureBlack,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.white54,
        elevation: 0,
      ),

      // Листы
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: lightGray,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),

      // Чипы
      chipTheme: ChipThemeData(
        backgroundColor: darkGray,
        selectedColor: primaryColor.withOpacity(0.3),
        labelStyle: const TextStyle(color: Colors.white),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Переключатели
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.white54;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor.withOpacity(0.5);
          }
          return Colors.white12;
        }),
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        side: const BorderSide(color: Colors.white54),
      ),

      // Radio
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.white54;
        }),
      ),

      // Слайдеры
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: Colors.white12,
        thumbColor: primaryColor,
        overlayColor: primaryColor.withOpacity(0.3),
      ),

      // Индикаторы прогресса
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: Colors.white12,
        circularTrackColor: Colors.white12,
      ),

      // Типографика
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w300),
        displayMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w400),
        displaySmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w400),
        headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w400),
        headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w400),
        headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w400),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(color: Colors.white70, fontWeight: FontWeight.w400),
        bodySmall: TextStyle(color: Colors.white60, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(color: Colors.white60, fontWeight: FontWeight.w500),
      ),
    );
  }
}

/// Расширение ThemeMode для AMOLED
enum ExtendedThemeMode {
  light,
  dark,
  amoled,
  system,
}

extension ExtendedThemeModeExtension on ExtendedThemeMode {
  static ExtendedThemeMode fromThemeMode(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return ExtendedThemeMode.light;
      case ThemeMode.dark:
        return ExtendedThemeMode.dark;
      case ThemeMode.system:
        return ExtendedThemeMode.system;
    }
  }

  ThemeMode get standardThemeMode {
    switch (this) {
      case ExtendedThemeMode.light:
        return ThemeMode.light;
      case ExtendedThemeMode.dark:
      case ExtendedThemeMode.amoled:
        return ThemeMode.dark;
      case ExtendedThemeMode.system:
        return ThemeMode.system;
    }
  }

  String get name {
    switch (this) {
      case ExtendedThemeMode.light:
        return 'light';
      case ExtendedThemeMode.dark:
        return 'dark';
      case ExtendedThemeMode.amoled:
        return 'amoled';
      case ExtendedThemeMode.system:
        return 'system';
    }
  }
}
