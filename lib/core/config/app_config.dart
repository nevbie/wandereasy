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

  /// URL-Vorlage für Rasterkacheln (`{z}/{x}/{y}`).
  // ANNAHME: Für Tests und wenige Nutzer die OSM-Standardkacheln (Entscheidung
  // des Vereins, abweichend von SPEC 9). Bei mehr Nutzern Anbieter eintragen.
  static const String mapTileUrl = String.fromEnvironment(
    'MAP_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  /// Zuordnung des Kartenanbieters, immer sichtbar (SPEC 9).
  static const String mapAttribution = String.fromEnvironment(
    'MAP_ATTRIBUTION',
    defaultValue: '© OpenStreetMap-Mitwirkende',
  );

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  /// `true`, wenn ein Backend konfiguriert ist. Sonst läuft die App mit
  /// Demo-Daten.
  static bool get hasBackend =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
