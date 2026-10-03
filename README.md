# Wandern mit den NaturFreunden

Wander-App für JungseniorInnen der NaturFreunde Veitshöchheim/Würzburg
(Arbeitstitel). Verbindliche Spezifikation: [`SPEC.md`](SPEC.md).
Getroffene Annahmen: [`DECISIONS.md`](DECISIONS.md). Änderungen:
[`CHANGELOG.md`](CHANGELOG.md).

## Entwicklung

Voraussetzung: Flutter (stable), für Android zusätzlich Android SDK und JDK 17.

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build   # nur nach Änderungen an Drift-Tabellen          # erzeugt lib/l10n/generated/ aus lib/l10n/app_de.arb
flutter analyze
flutter test
flutter run               # Standard: Demo-/Mock-Daten
```

Konfiguration per `--dart-define` (keine Secrets im Repo), siehe
`lib/core/config/app_config.dart`:

| Name | Bedeutung | Standard |
|---|---|---|
| `TRANSIT_PROVIDER` | `mock`, `static` (später `motis`, `trias`) | `mock` |
| `MAP_TILE_URL` | URL-Vorlage für Rasterkacheln `{z}/{x}/{y}` | OSM-Standardkacheln (nur für Tests/wenige Nutzer) |
| `MAP_ATTRIBUTION` | Zuordnung des Kartenanbieters | `© OpenStreetMap-Mitwirkende` |
| `SIMULATION` | Knopf „Probelauf ohne GPS“ in der Navigation | `true` (Testphase) |
| `SUPABASE_URL`, `SUPABASE_ANON_KEY` | Backend | – |

## Ordnerstruktur

```
lib/
  app.dart                 MaterialApp, Theme, Lokalisierung
  core/
    config/                --dart-define-Konfiguration
    providers/             austauschbare Anbieter (Transit, Fußwege, Wetter)
    routing/               go_router mit 4 Bereichen
    settings/              Darstellungs-Einstellungen
    theme/                 Farben (austauschbar) und Theme
    widgets/               gemeinsame Bausteine (Seitengerüst, untere Leiste)
  features/<bereich>/{data,domain,ui}/
  l10n/app_de.arb          alle Texte
supabase/migrations/       Datenbank-Schema (ab M5)
```

## Touren-Daten

- `assets/tours/` – Referenz-Routen (echte Strecken), erzeugt mit
  `python3 tools/import_reference_gpx.py <ordner-mit-gpx>`
- `assets/demo/` – Demo-Touren für Entwicklung und Tests
  (`python3 tools/make_demo_gpx.py`)

## Build (GitHub Actions)

`.github/workflows/build.yaml` läuft bei Push auf `main`, bei Pull Requests
auf `main` und manuell („Run workflow“). Er prüft Formatierung, Analyse und
Tests und baut ein Release-APK. Das APK liegt im Actions-Lauf unter
„Artifacts“ zum Herunterladen.

Optionale Secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
`ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` (ohne diese: Debug-Signatur),
`SUPABASE_URL`, `SUPABASE_ANON_KEY`. Optionale Variablen:
`TRANSIT_PROVIDER`, `MAP_TILE_URL`, `MAP_ATTRIBUTION`, `SIMULATION`.
