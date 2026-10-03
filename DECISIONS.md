# Entscheidungen und Annahmen

Annahmen sind im Code mit `// ANNAHME:` markiert. Punkte, die der Verein
klären muss, stehen in SPEC Abschnitt 16.

## M0

| # | Thema | Annahme / Entscheidung | Grund |
|---|---|---|---|
| D1 | Paketname, App-Name | `de.naturfreunde.wandern`, Dart-Paket `wandern`, Launcher-Name „NaturFreunde Wandern“ | Platzhalter laut SPEC; endgültiger Name offen (SPEC 16) |
| D2 | Farben | Markengrün `#1E6B34` als Konstante in `lib/core/theme/app_colors.dart`; restliche Farben aus Material 3 `ColorScheme.fromSeed` (Variante *fidelity*) | Nicht die offizielle Markenfarbe; austauschbar. Kontrast mit Weiß > 4,5:1 |
| D3 | Hochkontrast | Eigenes Theme über `contrastLevel: 1.0`; wird auch bei System-Hochkontrast genutzt | SPEC 4 verlangt Hochkontrast-Modus |
| D4 | Startseite | Die Startseite ist der Anfang des Bereichs „Wanderungen“ (`/`). „Wanderung suchen“ öffnet `/suche` innerhalb dieses Bereichs | SPEC 5 nennt Startseite und 4 Bereiche, aber nicht, wo die Startseite liegt |
| D5 | Kopfbereich statt `AppBar` | Eigenes Seitengerüst (`AppPage`): „Zurück“ oben links mit Text, darunter die Überschrift; wächst mit der Schrift | `AppBar` hat feste Höhe und schneidet bei 200 % Schrift ab |
| D6 | Untere Leiste | Eigene Leiste statt `NavigationBar`. Beschriftungen skalieren höchstens bis 130 % und werden notfalls verkleinert statt abgeschnitten | Vier Wörter wie „Wanderungen“ passen bei 200 % nicht nebeneinander auf ein Telefon; Inhaltstexte skalieren voll |
| D7 | Erneutes Tippen auf aktiven Bereich | Führt zum Anfang des Bereichs | Hilft, wenn man sich „verlaufen“ hat |
| D8 | Plattformen | Android + Web angelegt; iOS später (SPEC 3) | SPEC 7 |
| D9 | Generierte Lokalisierung | `lib/l10n/generated/` wird nicht eingecheckt, sondern per `flutter gen-l10n` erzeugt (auch in CI) | Vermeidet veraltete generierte Dateien |
| D10 | CI-Auslöser | Zusätzlich zu Push auf `main` und `workflow_dispatch` auch bei Pull Requests auf `main` | Fehler vor dem Zusammenführen erkennen |
| D11 | Einstellungen | `AppSettings` (Thema, Hochkontrast) vorerst nur im Speicher; Oberfläche und Speicherung folgen in M7 | Umfang M0 |
