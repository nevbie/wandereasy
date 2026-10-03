/// Build-Konfiguration per `--dart-define` (SPEC 7: keine Secrets im Repo).
///
/// Beispiel: `flutter run --dart-define=TRANSIT_PROVIDER=mock`
abstract final class AppConfig {
  /// Auswahl des TransitProviders: `mock` (Standard), `static`, später
  /// `motis` / `trias`.
  static const String transitProvider = String.fromEnvironment(
    'TRANSIT_PROVIDER',
    defaultValue: 'mock',
  );

  /// Style-URL des Vektorkarten-Anbieters (SPEC 9).
  static const String mapStyleUrl = String.fromEnvironment('MAP_STYLE_URL');

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  /// `true`, wenn ein Backend konfiguriert ist. Sonst läuft die App mit
  /// Demo-Daten.
  static bool get hasBackend =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
