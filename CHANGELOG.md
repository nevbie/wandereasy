# Changelog

## M0 – Projekt-Setup

- Flutter-Projekt `wandern` (Android, Web), Paketname `de.naturfreunde.wandern`, minSdk 26
- Ordnerstruktur nach Features (`lib/features/*/{data,domain,ui}`)
- Theme hell/dunkel/Hochkontrast mit Mindestgrößen (Text ≥ 18 sp, Überschriften ≥ 24 sp, Tippziele ≥ 56 dp)
- Lokalisierung über `lib/l10n/app_de.arb`
- `go_router` mit Startseite und genau 4 Bereichen: Wanderungen · Gruppen · Meine Touren · Hilfe (Platzhalter)
- „Zurück“ oben links mit Text; untere Leiste wächst mit der Schrift
- Build-Konfiguration per `--dart-define` (`AppConfig`)
- GitHub Actions: Format, Analyse, Tests, Release-APK als Artefakt; Signierung per Secret, sonst Debug
- Tests: Theme-Mindestgrößen, Navigation bei 100 % und 200 % Schrift, Barrierefreiheits-Richtlinien (Tippziele, Beschriftung, Kontrast) für alle Bildschirme
