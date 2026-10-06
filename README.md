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
supabase/
  migrations/              Datenbank-Schema mit Row Level Security
  tests/                   pgTAP-Tests der Zugriffsregeln (RLS)
  seed.sql                 Demo-Daten, erzeugt aus assets/demo (tools/make_seed_sql.py)
  config.toml              lokaler Supabase-Stack (supabase start)
tools/supabase_local/      Tests ohne Docker auf einfachem Postgres + PostGIS
```

## Datenbank (Supabase)

Schema, Zugriffsregeln und Seed liegen versioniert in `supabase/` – Änderungen nur als neue
Migration, nie von Hand im Dashboard. Jede Tabelle hat **Row Level Security**; der Anon-Key steckt
in der App, deshalb ist RLS der eigentliche Schutz. Regeln: SPEC 2/6, Entscheidungen D38–D42.

```bash
python3 tools/make_seed_sql.py      # Seed nach Änderungen an assets/demo neu erzeugen
supabase start && supabase test db  # mit Docker: echter lokaler Stack + pgTAP-Tests
tools/supabase_local/test.sh        # ohne Docker (Postgres + PostGIS + pgTAP installiert)
supabase db push                    # Migrationen ins verknüpfte Projekt (supabase link)
```

Betrieb: ein Supabase-Projekt für Entwicklung und ein eigenes für Produktion (Region Frankfurt,
SPEC 7); in Produktion Backups mit Point-in-Time-Recovery einschalten.

## Build (GitHub Actions)

`.github/workflows/build.yaml` läuft bei Push auf `main`, bei Pull Requests
auf `main` und manuell („Run workflow“). Er prüft Formatierung, Analyse und
Tests und baut ein Release-APK. Das APK liegt im Actions-Lauf unter
„Artifacts“ zum Herunterladen.

`.github/workflows/supabase.yaml` („Datenbank“) startet Supabase im Runner, wendet Migrationen
und Seed an, führt die RLS-Tests aus und prüft mit dem Linter. Einmalig auf GitHub:
*Settings → Branches* → `main` schützen, Pflicht-Checks „Prüfen und APK bauen“ und
„Schema und RLS prüfen“.

Optionale Secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
`ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` (ohne diese: Debug-Signatur),
`SUPABASE_URL`, `SUPABASE_ANON_KEY`. Optionale Variablen:
`TRANSIT_PROVIDER`, `MAP_TILE_URL`, `MAP_ATTRIBUTION`.
