import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_config.dart';

/// Уникальные темы QuikxChat с современным дизайном
abstract class UniqueQuikxThemes {
  static const double columnWidth = 380.0;
  static const double maxTimelineWidth = columnWidth * 2;
  static const double navRailWidth = 90.0;
  
  // Уникальные радиусы
  static const double borderRadiusXL = 28.0;
  static const double borderRadiusL = 20.0;
  static const double borderRadiusM = 16.0;
  static const double borderRadiusS = 12.0;
  static const double borderRadiusXS = 8.0;

  // Анимации
  static const Duration microAnimation = Duration(milliseconds: 100);
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);
  static const Duration extraLongAnimation = Duration(milliseconds: 800);

  // Кривые анимации
  static const Curve bouncyCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeInOutCubic;
  static const Curve fastCurve = Curves.easeOutExpo;
  static const Curve slowCurve = Curves.easeInOutSine;

  // Цветовые палитры
  static const Map<String, List<Color>> colorPalettes = {
    'cosmic': [
      Color(0xFF6B46C1), // Purple
      Color(0xFF3B82F6), // Blue
      Color(0xFF06B6D4), // Cyan
      Color(0xFF10B981), // Emerald
    ],
    'sunset': [
      Color(0xFFEF4444), // Red
      Color(0xFFF97316), // Orange
      Color(0xFFF59E0B), // Amber
      Color(0xFFEAB308), // Yellow
    ],
    'forest': [
      Color(0xFF059669), // Emerald
      Color(0xFF16A34A), // Green
      Color(0xFF65A30D), // Lime
      Color(0xFF84CC16), // Green-yellow
    ],
    'ocean': [
      Color(0xFF0EA5E9), // Sky
      Color(0xFF06B6D4), // Cyan
      Color(0xFF14B8A6), // Teal
      Color(0xFF10B981), // Emerald
    ],
    'aurora': [
      Color(0xFF8B5CF6), // Violet
      Color(0xFFA855F7), // Purple
      Color(0xFFEC4899), // Pink
      Color(0xFFF43F5E), // Rose
    ],
  };

  static bool isColumnModeByWidth(double width) =>
      width > columnWidth * 2 + navRailWidth;

  static bool isColumnMode(BuildContext context) =>
      isColumnModeByWidth(MediaQuery.sizeOf(context).width);

  static bool isThreeColumnMode(BuildContext context) =>
      MediaQuery.sizeOf(context).width > columnWidth * 3.5;

  /// Создает уникальный градиентный фон
  static LinearGradient createUniqueGradient(
    BuildContext context, {
    String palette = 'cosmic',
    double opacity = 0.1,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    final colors = colorPalettes[palette] ?? colorPalettes['cosmic']!;
    return LinearGradient(
      begin: begin,
      end: end,
      colors: colors.map((color) => color.withOpacity(opacity)).toList(),
      stops: const [0.0, 0.3, 0.7, 1.0],
    );
  }

  /// Создает анимированный градиент для фона
  static LinearGradient createAnimatedBackgroundGradient(
    BuildContext context, {
    String palette = 'cosmic',
    double animationValue = 0.0,
  }) {
    final colors = colorPalettes[palette] ?? colorPalettes['cosmic']!;
    final theme = Theme.of(context);
    
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      transform: GradientRotation(animationValue * 2 * 3.14159),
      colors: [
        theme.colorScheme.surface,
        colors[0].withOpacity(0.05),
        colors[1].withOpacity(0.08),
        colors[2].withOpacity(0.05),
        theme.colorScheme.surface,
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
    );
  }

  /// Уникальная тема с градиентами и анимациями
  static ThemeData buildUniqueTheme(
    BuildContext context,
    Brightness brightness, {
    Color? seedColor,
    String colorPalette = 'cosmic',
  }) {
    final palette = colorPalettes[colorPalette] ?? colorPalettes['cosmic']!;
    final primaryColor = seedColor ?? palette[0];
    
    final colorScheme = ColorScheme.fromSeed(
      brightness: brightness,
      seedColor: primaryColor,
      primary: palette[0],
      secondary: palette[1],
      tertiary: palette[2],
    );

    final isColumnModeValue = isColumnMode(context);
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      visualDensity: VisualDensity.comfortable,
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      
      // Уникальные цвета
      scaffoldBackgroundColor: isDark 
          ? const Color(0xFF0A0A0B)
          : const Color(0xFFFAFAFB),
      
      dividerColor: isDark
          ? colorScheme.outline.withOpacity(0.2)
          : colorScheme.outline.withOpacity(0.1),

      // Современная AppBar с градиентом
      appBarTheme: AppBarTheme(
        toolbarHeight: isColumnModeValue ? 80 : 64,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: 24,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: brightness == Brightness.dark 
              ? Brightness.light 
              : Brightness.dark,
          systemNavigationBarColor: isDark 
              ? const Color(0xFF0A0A0B)
              : const Color(0xFFFAFAFB),
          systemNavigationBarIconBrightness: brightness == Brightness.dark 
              ? Brightness.light 
              : Brightness.dark,
        ),
      ),

      // Уникальные кнопки с градиентами
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusL),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // Стильные карточки
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusL),
          side: BorderSide(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        color: isDark 
            ? colorScheme.surface.withOpacity(0.8)
            : colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),

      // Уникальные поля ввода
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark 
            ? colorScheme.surface.withOpacity(0.5)
            : colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusL),
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusL),
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusL),
          borderSide: BorderSide(
            color: palette[0],
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withOpacity(0.6),
          fontWeight: FontWeight.w400,
        ),
      ),

      // Стильные чипы
      chipTheme: ChipThemeData(
        backgroundColor: palette[0].withOpacity(0.1),
        selectedColor: palette[0].withOpacity(0.2),
        labelStyle: TextStyle(
          color: palette[0],
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusXL),
        ),
        showCheckmark: false,
      ),

      // Уникальные снэкбары
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark 
            ? colorScheme.surface 
            : colorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          color: isDark 
              ? colorScheme.onSurface 
              : colorScheme.onInverseSurface,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusL),
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(isColumnModeValue ? 24 : 16),
      ),

      // Современные попап меню
      popupMenuTheme: PopupMenuThemeData(
        color: isDark 
            ? colorScheme.surface 
            : colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusL),
          side: BorderSide(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        textStyle: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Стильные диалоги
      dialogTheme: DialogTheme(
        backgroundColor: isDark 
            ? colorScheme.surface 
            : colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusXL),
        ),
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(
          color: colorScheme.onSurface.withOpacity(0.8),
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Уникальная типографика
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
          color: colorScheme.onSurface,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          color: colorScheme.onSurface,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.6,
          color: colorScheme.onSurface,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
          color: colorScheme.onSurface,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: colorScheme.onSurface,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
          color: colorScheme.onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
          color: colorScheme.onSurface.withOpacity(0.8),
        ),
      ),
    );
  }

  /// Создает тему для пузырей сообщений
  static BoxDecoration createMessageBubbleDecoration({
    required BuildContext context,
    required bool isOwnMessage,
    String colorPalette = 'cosmic',
  }) {
    final palette = colorPalettes[colorPalette] ?? colorPalettes['cosmic']!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isOwnMessage) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette[0],
            palette[1],
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadiusL),
        boxShadow: [
          BoxShadow(
            color: palette[0].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );
    } else {
      return BoxDecoration(
        color: isDark 
            ? theme.colorScheme.surface.withOpacity(0.8)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadiusL),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      );
    }
  }

  /// Создает анимированный эффект для аватара
  static BoxDecoration createAvatarDecoration({
    required BuildContext context,
    String colorPalette = 'cosmic',
    double animationValue = 0.0,
  }) {
    final palette = colorPalettes[colorPalette] ?? colorPalettes['cosmic']!;
    
    return BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        transform: GradientRotation(animationValue * 2 * 3.14159),
        colors: [
          palette[0].withOpacity(0.8),
          palette[1].withOpacity(0.6),
          palette[2].withOpacity(0.8),
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: palette[0].withOpacity(0.4),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

/// Расширение для цветов пузырей
extension UniqueBubbleColors on ThemeData {
  Color get uniqueBubbleColor => brightness == Brightness.light
      ? const Color(0xFF6B46C1)
      : const Color(0xFF8B5CF6);

  Color get uniqueOnBubbleColor => Colors.white;

  Color get uniqueSecondaryBubbleColor => brightness == Brightness.light
      ? colorScheme.surface
      : colorScheme.surface.withOpacity(0.8);
}
