# Changelog

## M1 – Suche, Tourenliste, Tour-Detail

- Startpunkt-Wahl (Naturfreundehaus / Bahnhof Veitshöchheim) beim ersten Start und jederzeit über „ändern“; gespeichert
- Drei Tourenarten (Rundweg, Loslaufen + Rückfahrt, Hin- und Rückfahrt mit A ≠ B)
- Fragen-Suche, je Frage ein Bildschirm (Tourenart, Gehzeit, Anstrengung, Einkehr, bei Hin- und Rückfahrt zusätzlich Fahrzeit); „Alle Touren zeigen“
- Vorschläge als große Karten (Tourenart, Gehzeit, Schwierigkeit mit Farbe und Text, Fahrzeit, Einkehr-Hinweis); Hinweis bei 0 Treffern
- Tour-Detail mit Kurzfazit, Hauptknopf „Verbindung zeigen“ / „Tagesablauf zeigen“ (Ziel folgt in M4), Höhenprofil, Einkehren, Unterwegs, Wege, Hinweise, Abkürzungen
- Einkehr-Block mit Öffnungslogik (Ruhetag, OSM-Öffnungszeiten, Saison), „Am Samstag geöffnet“ / „Am Montag Ruhetag“, Tag wählbar, Anrufen-Knopf
- Reine Funktionen mit Tests: Filterlogik (alle Tourenart × Startpunkt), Öffnungslogik, GPX-Parser, Länge/Höhenmeter, Gehzeit nach DIN 33466, Formatierung
- Demo-Daten: 3 synthetische Touren (je Tourenart eine) mit Demo-Einkehr, Platzhalter Natura Trail Höhfeldplatte (unveröffentlicht); Generator `tools/make_demo_gpx.py`
- Barrierefreiheitstests für alle neuen Bildschirme bei 100 % und 200 % Schrift

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
