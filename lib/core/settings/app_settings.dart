import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Darstellungs-Einstellungen. Die Oberfläche dafür folgt in M7
/// (Hilfe → Einstellungen); bis dahin gelten die Standardwerte.
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.light,
    this.highContrast = false,
  });

  /// Hell ist Standard (SPEC 4: „Hell als Standard, Dunkel optional“).
  final ThemeMode themeMode;
  final bool highContrast;

  AppSettings copyWith({ThemeMode? themeMode, bool? highContrast}) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        highContrast: highContrast ?? this.highContrast,
      );
}

class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => const AppSettings();

  void setThemeMode(ThemeMode mode) => state = state.copyWith(themeMode: mode);

  void setHighContrast(bool value) =>
      state = state.copyWith(highContrast: value);
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);
