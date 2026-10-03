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

## M2

| # | Thema | Annahme / Entscheidung | Grund |
|---|---|---|---|
| D27 | Kartenkacheln | **OSM-Standardkacheln** (`tile.openstreetmap.org`) für Tests und wenige Nutzer, mit User-Agent `de.naturfreunde.wandern` und immer sichtbarer Zuordnung. Per `MAP_TILE_URL` / `MAP_ATTRIBUTION` austauschbar | Entscheidung des Vereins (noch kein Anbieter), **abweichend von SPEC 9**. Vor breiter Nutzung Anbieter wählen (OSM Tile Usage Policy) |
| D28 | Kartenbibliothek | `flutter_map` (Raster) statt `maplibre_gl` (Vektor) | Für Rasterkacheln genügt `flutter_map`; reines Dart, in Widget-Tests und im Web testbar, eingebauter Kachel-Cache. Bei Wechsel auf Vektorkacheln neu bewerten (`vector_map_tiles` oder `maplibre_gl`) |
| D29 | Offline-Karte | **Kein Vorab-Download** von Kartenausschnitten (OSM-Richtlinie verbietet Bulk-Download). Stattdessen: angesehene Kacheln werden gecacht (App-Verzeichnis, max. 300 MB, HTTP-Cache-Regeln). Ohne Netz werden auch veraltete Kacheln gezeigt (`OfflineTolerantCachingProvider`, keine Zusatzanfragen). Route, Start/Ziel, Einkehr und POIs zeichnet die App selbst – sie sind offline immer sichtbar. Hinweistext unter der Karte im Offline-Fall | SPEC 9 (Zoom 10–16 vorab) erst mit eigenem Anbieter/PMTiles möglich |
| D30 | Speichergröße / WLAN | Angezeigt wird die Größe der Tourdaten (wenige KB). Keine WLAN-Abfrage, da nichts Großes geladen wird | Folgt aus D29 |
| D31 | Lage von Einkehr/POIs | Ohne eigene Koordinaten aus der km-Angabe auf der Route berechnet (`positionAtDistance`) | Demo-Daten haben nur km-Angaben |
| D32 | Kartenbedienung | Ziehen und Zwei-Finger-Zoom möglich, Drehen aus; Zoom zusätzlich über „+“/„−“ (56 dp) | SPEC 4: einfache Tippbedienung muss reichen |
| D33 | Beschriftungen auf der Karte | Feste Schriftgröße (16), notfalls verkleinert | Kartenbeschriftungen können nicht mitwachsen; volle Angaben stehen in den Listen darunter |
| D34 | Offline-Ablage | Drift-Tabelle `saved_tours` mit der vollständigen Tour als JSON. Tour-Detail lädt bei fehlender Verbindung aus der Ablage. Generierter Code (`*.g.dart`) wird eingecheckt | Einfach, robust; Schema wächst mit M5 |
| D35 | Meine Touren | Je Tour „Wanderung starten“ (Navigation folgt in M3), „Tour ansehen“, „Löschen“ mit Bestätigung „Ja, löschen“ / „Nein, zurück“ | SPEC 4, 5.6 |
| D36 | Kein-Internet-Hinweis | Leiste über der unteren Navigation (connectivity_plus); im Zweifel gilt „online“ | SPEC 4 „Ladezustände“ |
| D37 | Web | Offline-Speichern im Web nicht eingerichtet (Drift/WASM) | Web ist nur für die Tourenleitung (M6) |

## M3

| # | Thema | Annahme / Entscheidung | Grund |
|---|---|---|---|
| D38 | Abweichung | > 40 m für ≥ 20 s → Vibration + Ansage + rotes Banner. „Wieder auf dem Weg“ erst unter 30 m (Hysterese). Warnung wird jede Minute wiederholt, solange man abseits bleibt. Werte in `NavigationConfig` | SPEC 5.7; Hysterese und Wiederholung ergänzt, damit es an der Grenze nicht flackert und niemand die Warnung verpasst |
| D39 | Ungenauer Standort | Standorte mit Genauigkeit > 50 m lösen keine Warnung aus | Im Wald/Tal sonst Fehlalarme |
| D40 | Stillstand | Zeit läuft per Takt (alle 5 s) weiter, auch wenn wegen des 10-m-Filters keine Standorte kommen | Sonst keine Warnung, wenn man abseits stehen bleibt |
| D41 | Position auf der Route | Suche bevorzugt nahe der letzten Position (150 m zurück, 1 km voraus); bei Rundwegen gewinnt am Start der Anfang. Liegt man im Suchfenster weit weg, an anderer Stelle aber auf der Route, gilt diese (Abkürzung) | Rundwege und doppelt begangene Wege |
| D42 | Ziel erreicht | Weniger als 40 m vor dem Ende der Route | — |
| D43 | Einkehr-Ansage | Einmal, sobald sie ≤ 300 m voraus liegt („In 300 Metern: …“); nicht während einer Abweichung | SPEC 5.11 |
| D44 | „Nächster POI“ | Nächstes Ziel auf der Route: Einkehr oder POI (ohne Abkürzungen) | SPEC 5.7 |
| D45 | Vordergrunddienst | Über `geolocator` (`ForegroundNotificationConfig`, „Navigation läuft“), Standort alle 5 s / 10 m. Keine Hintergrund-Standortberechtigung nötig. Benachrichtigungs-Berechtigung (Android 13+) wird nicht extra abgefragt; ohne sie läuft der Dienst trotzdem | SPEC 5.7, 10 |
| D46 | Pause | Standort wird während der Pause nicht verfolgt (Akku), keine Warnungen | — |
| D47 | Während der Navigation | Kein „Zurück“-Knopf; Verlassen nur über „Wanderung beenden“ mit Bestätigung | Versehentliches Beenden vermeiden |
| D48 | Probelauf ohne GPS | Knopf „Probelauf ohne GPS“ (Zeitraffer mit einem Abstecher) zum Ausprobieren zu Hause; per `SIMULATION=false` abschaltbar. **Für den Pilot (M8) abschalten** | Testen ohne Wanderung |
| D49 | Sprachansagen | `flutter_tts` (de-DE, etwas langsamer); an/aus folgt mit den Einstellungen (M7), bis dahin an | SPEC 5.7, 5.9 |
| D50 | Abkürzen | Knopf führt vorerst zu einem Platzhalter; Inhalt (nächste Haltestellen) kommt mit M4 | SPEC 5.8 gehört zu M4 |

## Änderungswunsch 03.10.2026 (längere Touren, Einkehr am Schluss, Landschaft, Anfahrt)

| # | Thema | Annahme / Entscheidung | Grund |
|---|---|---|---|
| D51 | „bis 15/20 km je nach Höhenprofil“ | Strecke ≤ 20 km und Leistungskilometer (km + Hm bergauf/100) ≤ 20. Gilt für Vorschläge, nicht für „Alle Touren“ | Übliches Maß (Leistungskilometer); ergibt genau 20 km flach bzw. 15 km bei 500 Hm |
| D52 | „Einkehr eher am Schluss“ | Am Ziel, im letzten Drittel oder in den letzten 2 km. Wirkt als Bevorzugung in der Rangfolge, nicht als Ausschluss. Kurzfazit: „Einkehr am Ziel“ / „Einkehr zum Schluss“ / „Einkehr unterwegs“ | Touren mit Einkehr in der Mitte sollen weiter auffindbar bleiben |
| D53 | „landschaftlich schön“ | Gepflegtes Feld `scenery` (3 Stufen) statt automatischer Ableitung | Schönheit lässt sich nicht verlässlich aus Daten berechnen; Tourenleitung kennt die Strecken |
| D54 | „bis zu 1 h Anfahrt“ | Standard-Obergrenze 60 Min. einfache Fahrt inkl. Fußweg vom Startpunkt, für alle Touren mit Bus/Bahn (auch ohne Fahrzeit-Frage). „Egal“ hebt sie auf | Wunsch des Vereins |
| D55 | „bevorzugt ohne Umsteigen“ | Rangfolge: direkt +2, 1 Umstieg ±0, jeder weitere −2. Unbekannt = neutral. Karte zeigt „ohne Umsteigen“ / „1-mal umsteigen“ | Bevorzugen, nicht ausschließen |
| D56 | Gewichtung | Landschaft je Stufe +4, Einkehr am Schluss +3 (unterwegs +1), ohne Umsteigen +2; dann kürzere Gehzeit | Landschaft am wichtigsten, Werte in `SuggestionRules` anpassbar |
| D57 | Demo-Daten | Drei weitere Demo-Touren: lange Tour mit Direktverbindung und Einkehr am Ziel (16,5 km), Tour mit Umstieg (55 Min.), zu lange Runde (21,5 km, nur unter „Alle Touren“) | Neue Regeln sichtbar und testbar |
