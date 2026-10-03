import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Mindestgrößen aus SPEC 4 (UX-Regeln).
abstract final class AppSizes {
  /// Mindestgröße eines Tippziels in dp.
  static const double minTapTarget = 56;

  /// Mindestabstand zwischen Tippzielen in dp.
  static const double tapTargetGap = 8;

  /// Fließtext mindestens 18 sp.
  static const double minBodyFontSize = 18;

  /// Überschriften mindestens 24 sp.
  static const double minHeadingFontSize = 24;

  /// Seitenrand.
  static const double pagePadding = 16;
}

abstract final class AppTheme {
  static ThemeData light({bool highContrast = false}) =>
      _build(Brightness.light, highContrast);

  static ThemeData dark({bool highContrast = false}) =>
      _build(Brightness.dark, highContrast);

  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 48),
    displayMedium: TextStyle(fontSize: 40),
    displaySmall: TextStyle(fontSize: 34),
    headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
    headlineSmall: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 20, height: 1.4),
    bodyMedium: TextStyle(fontSize: 18, height: 1.4),
    bodySmall: TextStyle(fontSize: 18, height: 1.4),
    labelLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    labelSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
  );

  static ThemeData _build(Brightness brightness, bool highContrast) {
    var scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandGreen,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      contrastLevel: highContrast ? 1.0 : 0.0,
    );
    if (brightness == Brightness.light && !highContrast) {
      scheme = scheme.copyWith(
        primary: AppColors.brandGreen,
        onPrimary: Colors.white,
      );
    }

    const buttonPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 14);
    const buttonMinSize = Size(AppSizes.minTapTarget, AppSizes.minTapTarget);
    final buttonText = _textTheme.labelLarge;
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: _textTheme,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          textStyle: buttonText,
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          textStyle: buttonText,
          shape: buttonShape,
          side: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: buttonMinSize,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          textStyle: buttonText,
        ),
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        shape: buttonShape,
        color: scheme.surfaceContainerLow,
      ),
    );
  }
}
