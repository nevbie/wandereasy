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

## M1

| # | Thema | Annahme / Entscheidung | Grund |
|---|---|---|---|
| D12 | Koordinaten der Startpunkte | `location = null` für Naturfreundehaus und Bahnhof | SPEC 11: nicht erfinden. Geocoding (Nominatim) war aus der Entwicklungsumgebung nicht erreichbar → **vom Verein bestätigen oder in M4 per Geocoding ermitteln** |
| D13 | Fußweg Naturfreundehaus → Bahnhof | Demo-Schätzung 15 Min. (`lib/features/tour/domain/start_point.dart`) | Wird in M4 per Fußwege-Routing berechnet |
| D14 | Demo-Touren | Synthetische Routen aus `tools/make_demo_gpx.py`, Namen beginnen mit „DEMO“, Einkehr-Namen ebenfalls; keine Telefonnummern (damit niemand versehentlich echte Nummern anruft) | SPEC 11 |
| D15 | Fahrzeiten | Je Tour gepflegte Schätzwerte `ride.toStartMin` / `ride.fromEndMin` ab Bahnhof (Demo); Fahrzeit-Frage nutzt die längere Richtung plus Fußweg vom Startpunkt | Echte Zeiten kommen mit dem TransitProvider (M4) |
| D16 | Antwort „mittel“ | Bedeutet „höchstens mittel“ (leicht + mittel) | Sonst würden leichte Touren bei „mittel“ fehlen |
| D17 | Grenzen Gehzeit | bis 2 Std. = ≤ 120 Min.; 2–4 Std. = 121–240 Min.; länger = > 240 Min. (reine Gehzeit ohne Pausen) | Eindeutige Zuordnung |
| D18 | Einkehr mit Datum | Unbekannte Öffnungszeiten werden nicht ausgefiltert, sondern mit „Öffnungszeiten bitte vorher prüfen“ angezeigt | Lieber zeigen und warnen als gute Touren verstecken |
| D19 | Öffnungszeiten | Nur Teilmenge der OSM-Syntax (Wochentage, `off`, `24/7`, `PH` ignoriert); alles andere = unbekannt. Saison wiederkehrend ohne Jahr (`MM-DD`), auch über den Jahreswechsel | Für „an diesem Tag geöffnet?“ ausreichend; Uhrzeiten zählen erst im Tagesablauf |
| D20 | Geplanter Tag | Standard heute; im Einkehr-Block über „Tag ändern“ wählbar. Die Suche fragt (noch) kein Datum ab | SPEC 5.2 sieht keine Datumsfrage vor; Datum gehört zum Tagesablauf (M4) |
| D21 | Startpunkt-Wahl | Erscheint, solange noch kein Startpunkt gewählt ist, statt der Startseite; Wahl wird mit `shared_preferences` gespeichert | „Beim allerersten Start“ (SPEC 5.2) |
| D22 | Frage 1 „mit Bild“ | Große Symbole statt Fotos | Noch keine Bilder vorhanden |
| D23 | Vorschlagskarten | Ohne Foto; höchstens 5, sortiert nach Gehzeit | Keine Fotos in den Demo-Daten |
| D24 | Tour-Detail | Karte und „Für unterwegs speichern“ fehlen noch | Kommen mit M2 |
| D25 | Höhenmeter | Hysterese-Schwelle 3 m gegen GPS-Rauschen | Übliches Verfahren; Wert anpassbar |
| D26 | Knöpfe mit Symbol | Eigener Inhalt `IconLabel` statt `FilledButton.icon` | `.icon`-Varianten brechen nicht um und liefen bei 200 % Schrift über |
