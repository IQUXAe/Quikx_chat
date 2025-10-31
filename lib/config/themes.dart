import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_config.dart';

abstract class QuikxChatThemes {
  static const double columnWidth = 420.0;

  static const double maxTimelineWidth = columnWidth * 2;

  static const double navRailWidth = 90.0;

  static bool isColumnModeByWidth(double width) =>
      width > columnWidth * 2 + navRailWidth;

  static bool isColumnMode(BuildContext context) =>
      isColumnModeByWidth(MediaQuery.sizeOf(context).width);

  static bool isThreeColumnMode(BuildContext context) =>
      MediaQuery.sizeOf(context).width > QuikxChatThemes.columnWidth * 3.5;

  static LinearGradient backgroundGradient(
    BuildContext context,
    int alpha,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return LinearGradient(
      begin: Alignment.topCenter,
      colors: [
        colorScheme.primaryContainer.withAlpha(alpha),
        colorScheme.secondaryContainer.withAlpha(alpha),
        colorScheme.tertiaryContainer.withAlpha(alpha),
        colorScheme.primaryContainer.withAlpha(alpha),
      ],
    );
  }

  static const Duration animationDuration = Duration(milliseconds: 400);
  static const Duration fastAnimationDuration = Duration(milliseconds: 250);
  static const Duration slowAnimationDuration = Duration(milliseconds: 550);
  static const Curve animationCurve = Curves.easeInOutCubic;
  static const Curve fastAnimationCurve = Curves.easeOutQuart;
  static const Curve bounceAnimationCurve = Curves.elasticOut;
  static const Curve slideAnimationCurve = Curves.easeInOutCubic;

  static ThemeData buildTheme(
    BuildContext context,
    Brightness brightness, [
    Color? seed,
    bool useAmoled = false,
  ]) {
    final colorScheme = useAmoled && brightness == Brightness.dark
        ? ColorScheme.fromSeed(
            brightness: brightness,
            seedColor: seed ?? AppConfig.colorSchemeSeed ?? const Color(0xFF6366F1),
            dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
          ).copyWith(
            surface: Colors.black,
            surfaceContainerLowest: Colors.black,
            surfaceContainerLow: const Color(0xFF0A0A0A),
            surfaceContainer: const Color(0xFF121212),
            surfaceContainerHigh: const Color(0xFF1A1A1A),
            surfaceContainerHighest: const Color(0xFF222222),
          )
        : ColorScheme.fromSeed(
            brightness: brightness,
            seedColor: seed ?? AppConfig.colorSchemeSeed ?? const Color(0xFF6366F1),
            dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
          );
    final isColumnMode = QuikxChatThemes.isColumnMode(context);
    return ThemeData(
      visualDensity: VisualDensity.standard,
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      dividerColor: Colors.transparent,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        color: brightness == Brightness.dark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : colorScheme.surfaceContainerLow,
      ),
      popupMenuTheme: PopupMenuThemeData(
        elevation: 8,
        color: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: colorScheme.primary.withValues(alpha: 0.3),
        selectionHandleColor: colorScheme.primary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        showCheckmark: false,
        backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      appBarTheme: kIsWeb
          ? const AppBarTheme(
              toolbarHeight: 64,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              backgroundColor: Colors.transparent,
            )
          : AppBarTheme(
              toolbarHeight: 64,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              backgroundColor: Colors.transparent,
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: brightness.reversed,
                statusBarBrightness: brightness,
                systemNavigationBarIconBrightness: brightness.reversed,
                systemNavigationBarColor: colorScheme.surface,
              ),
            ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(width: 2, color: colorScheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        width: isColumnMode ? QuikxChatThemes.columnWidth * 1.5 : null,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 2,
          shadowColor: colorScheme.primary.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

extension on Brightness {
  Brightness get reversed =>
      this == Brightness.dark ? Brightness.light : Brightness.dark;
}

extension BubbleColorTheme on ThemeData {
  Color get bubbleColor => colorScheme.primary;

  Color get onBubbleColor => colorScheme.onPrimary;

  Color get secondaryBubbleColor => brightness == Brightness.light
      ? colorScheme.surfaceContainerHighest
      : colorScheme.surfaceContainerHigh;

  LinearGradient get bubbleGradient => LinearGradient(
        colors: [
          colorScheme.primary,
          colorScheme.primary.withValues(alpha: 0.8),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}