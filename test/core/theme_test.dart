import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandern/core/theme/app_theme.dart';

void main() {
  final themes = {
    'hell': AppTheme.light(),
    'dunkel': AppTheme.dark(),
    'hell, Hochkontrast': AppTheme.light(highContrast: true),
    'dunkel, Hochkontrast': AppTheme.dark(highContrast: true),
  };

  for (final MapEntry(key: name, value: theme) in themes.entries) {
    group('Theme $name', () {
      final t = theme.textTheme;

      test('Fließtext und Beschriftungen mindestens 18 sp', () {
        for (final style in [
          t.bodyLarge,
          t.bodyMedium,
          t.bodySmall,
          t.labelLarge,
          t.labelMedium,
          t.labelSmall,
          t.titleMedium,
          t.titleSmall,
        ]) {
          expect(style!.fontSize, greaterThanOrEqualTo(18));
        }
      });

      test('Überschriften mindestens 24 sp', () {
        for (final style in [
          t.titleLarge,
          t.headlineSmall,
          t.headlineMedium,
          t.headlineLarge,
          t.displaySmall,
        ]) {
          expect(style!.fontSize, greaterThanOrEqualTo(24));
        }
      });

      test('Knöpfe mindestens 56 dp hoch', () {
        const states = <WidgetState>{};
        for (final style in [
          theme.filledButtonTheme.style,
          theme.outlinedButtonTheme.style,
          theme.textButtonTheme.style,
        ]) {
          final min = style!.minimumSize!.resolve(states)!;
          expect(min.height, greaterThanOrEqualTo(56));
          expect(min.width, greaterThanOrEqualTo(56));
        }
      });
    });
  }

  test('Hell ist Standardthema mit Markengrün', () {
    expect(AppTheme.light().brightness, Brightness.light);
    expect(AppTheme.light().colorScheme.primary, const Color(0xFF1E6B34));
  });
}
