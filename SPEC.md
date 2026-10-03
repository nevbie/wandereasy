# SPEC – Wander-App für JungseniorInnen (NaturFreunde Veitshöchheim/Würzburg)

> **An Claude Code:** Diese Datei ist die verbindliche Spezifikation. Lies sie vollständig, bevor du Code schreibst.
> Arbeite die Meilensteine (Abschnitt 14) **der Reihe nach** ab, jeweils mit Tests und lauffähigem Build.
> Erfinde keine Fahrplan-, Koordinaten- oder Tourendaten: Wo Daten fehlen, nutze klar markierte Demo-Daten (`isDemo: true`).
> Bei Punkten aus „Offene Punkte“ (Abschnitt 16): sinnvolle Annahme treffen, im Code mit `// ANNAHME:` markieren und in `DECISIONS.md` festhalten.

Arbeitstitel der App: **„Wandern mit den NaturFreunden“** (Paketname: `de.naturfreunde.wandern` – Platzhalter, siehe Offene Punkte).

---

## 1. Ziel

Die App beantwortet für jede Wanderung in Veitshöchheim, Würzburg und Umgebung drei Fragen:

1. **Wie komme ich mit Bus und Bahn hin und wieder zurück?**
2. **Schaffe ich die Strecke?** (Gehzeit, Länge, Höhenmeter, Wege, Pausen)
3. **Wo geht es lang?** (Karte, einfache Navigation unterwegs)

Sie muss von Menschen ab ca. 60 Jahren bedient werden können, die wenig Erfahrung mit Smartphones haben. **Einfachheit hat Vorrang vor Funktionsumfang.**

### Kontext

- Ortsgruppe: NaturFreunde Veitshöchheim/Würzburg e. V. Bietet u. a. Jungsenioren-Wanderungen (Tempo ca. 4 km/h) an.
- Typischer Treffpunkt: Naturfreundehaus „Am Kalten Brunnen“, Sendelbachstraße 146, 97209 Veitshöchheim.
- ÖPNV: Bahnhof Veitshöchheim (Main-Spessart-Bahn, stündlich Regionalzüge), VVM-Buslinien 11 und 19 nach Würzburg. Verbund: VVM (Verkehrsunternehmens-Verbund Mainfranken).
- Vereinseigene Tour: Natura Trail „Höhfeldplatte“, Rundweg ca. 15,4 km (GPX liefert der Verein).

### Startpunkte und Tourenarten (zentral für die ganze App)

**Startpunkte** (Auswahl beim ersten Start, jederzeit änderbar; genau diese zwei):

| ID | Name | Hinweis |
|---|---|---|
| `nfh_vhh` | Naturfreundehaus Veitshöchheim („Am Kalten Brunnen“, Sendelbachstraße 146) | Vereinstreffpunkt; Fußweg zur nächsten Haltestelle wird berechnet und angezeigt |
| `bf_vhh` | Bahnhof Veitshöchheim | Bahn + Bus |

Beide Startpunkte sind auch der **Endpunkt** („nach Hause“) für Rückfahrten.

**Tourenarten** (`tour_type`):

| Typ | Ablauf | ÖPNV-Fahrten |
|---|---|---|
| `loop` – Rundweg ab Startpunkt | zu Fuß los, zu Fuß zurück | 0 |
| `walk_out_ride_back` – Loslaufen, mit Bus/Bahn zurück | Startpunkt → zu Fuß → Ziel B → ÖPNV → Startpunkt | 1 (Rückfahrt) |
| `ride_both_ways` – Streckenwanderung mit Hin- und Rückfahrt | Startpunkt → ÖPNV → A → zu Fuß → B → ÖPNV → Startpunkt (A ≠ B möglich) | 2 (Hin- und Rückfahrt) |

Für jede Tour berechnet/zeigt die App passend zum Typ: Fußweg vom Startpunkt zur Haltestelle, Hinfahrt, Wanderung, Rückfahrt, Fußweg zurück – als **eine durchgehende Tagesübersicht** (siehe 5.5).

## 2. Rollen

| Rolle | Rechte | Oberfläche |
|---|---|---|
| `guest` (ohne Konto) | Touren ansehen, suchen, offline speichern, navigieren, Hilfe-Funktionen | App |
| `member` (mit Konto) | zusätzlich: für Gruppenwanderungen an-/abmelden, Mitteilungen der Tourenleitung erhalten | App |
| `tour_leader` | zusätzlich: Touren anlegen/bearbeiten (GPX-Import), Gruppenwanderungen ausschreiben/absagen, Teilnehmerliste sehen, Mitteilung an Angemeldete senden | App + Web (Flutter Web, gleiche Codebasis) |
| `admin` | zusätzlich: Rollen vergeben, Touren freigeben/löschen | Web |

Teilnehmende sehen **niemals** Verwaltungsfunktionen.

## 3. Umfang

### MVP (muss)

- Startpunkt-Auswahl (Naturfreundehaus / Bahnhof Veitshöchheim)
- Drei Tourenarten (Rundweg, Loslaufen + Rückfahrt, Hin- und Rückfahrt mit A ≠ B)
- Tourenliste + Suche über wenige einfache Fragen
- Tour-Detail mit Kurzfazit, Karte, Höhenprofil, Infos (WC, Bänke)
- Einkehrmöglichkeiten: auf Karte und als Liste, mit Ruhetag/Öffnungszeiten, als Suchkriterium
- ÖV-Anreise/Rückfahrt (siehe Abschnitt 8, Stufe 1)
- Tour offline speichern (Karte + Route + Infos)
- Navigation unterwegs: Standort auf Route, Restdistanz, Warnung bei Abweichung (Vibration + Sprache)
- „Ich möchte abkürzen“: nächste Haltestelle zu Fuß
- Hilfe-Bereich: Notruf 112, Standort teilen
- Gruppenwanderungen: Liste, Detail, Anmeldung (Konto per SMS-Code)
- Tourenleitung: Tour per GPX anlegen, Gruppenwanderung ausschreiben/absagen, Mitteilung senden
- Android-APK per GitHub Actions

### Später (nicht im MVP)

- iOS-Build und Store-Veröffentlichung
- Verbindungssuche mit Echtzeit (Stufe 2/3, Abschnitt 8)
- Wetter-Erinnerung am Vorabend
- Fotos von Teilnehmenden, Tourenberichte

### Nicht-Ziele

- Kein Fitness-Tracking, keine Ranglisten, keine Social-Feeds
- Kein eigener Ticketverkauf
- Keine Speicherung von Standortverläufen auf dem Server
- Keine Werbung, kein Analytics-Tracking

## 4. UX-Regeln (verbindlich, testbar)

| Regel | Vorgabe |
|---|---|
| Schriftgröße | Fließtext ≥ 18 sp, Überschriften ≥ 24 sp; System-Schriftskalierung bis 200 % ohne abgeschnittenen Text |
| Tippziele | ≥ 56 × 56 dp, Abstand ≥ 8 dp |
| Kontrast | WCAG 2.1 AA (Text ≥ 4,5:1), zusätzlich ein Hochkontrast-Modus in den Einstellungen |
| Beschriftung | Jeder Knopf hat sichtbaren Text. Icons nur zusätzlich zum Text |
| Gesten | Nur einfaches Tippen. Kein Wischen, Gedrückthalten, Doppeltippen als einzige Bedienmöglichkeit. Karte: Zoom auch über +/− Knöpfe |
| Navigation | Untere Leiste mit genau 4 Bereichen: **Wanderungen · Gruppen · Meine Touren · Hilfe**. „Zurück“ immer oben links mit Text |
| Ein Schritt pro Bildschirm | Jeder Bildschirm hat **einen** hervorgehobenen Hauptknopf |
| Sprache | Deutsch, kurze Sätze, Sie-Form. Gehzeit in Std./Min., nicht km/h. Schwierigkeit als „leicht / mittel / anspruchsvoll“ mit Farbe **und** Text |
| Fehler | Destruktive Aktionen (Abmelden, Tour löschen) mit Bestätigungsdialog, Knöpfe „Ja, abmelden“ / „Nein, zurück“. Fehlermeldungen sagen, was zu tun ist |
| Barrierefreiheit | Vollständige `Semantics`-Labels, nutzbar mit TalkBack/VoiceOver |
| Ladezustände | Nie leerer Bildschirm: Text „Wird geladen …“ + Fortschritt; offline klarer Hinweis „Kein Internet – gespeicherte Touren funktionieren trotzdem“ |
| Theme | Hell als Standard, Dunkel optional. Farbschema an NaturFreunde-Grün angelehnt (Farbwerte als Konstanten, austauschbar) |

Beispiel-Texte (Microcopy):

- Hauptknopf Tour-Detail: „Verbindung zeigen“
- Kurzfazit: „2 ½ Std. · leicht · 9 km · 120 m bergauf · Einkehr unterwegs“
- Navigation: „Noch 1,2 km bis zur Einkehr“ / „Sie sind vom Weg abgekommen. Bitte etwa 50 m zurückgehen.“

## 5. Bildschirme und Abläufe

Bereiche und Bildschirme (je Bereich ein gerader Weg ohne Verzweigungen):

```
Startseite (3 große Knöpfe: Wanderung suchen · Gruppenwanderungen · Meine Touren)
├── Wanderungen: (Startpunkt) → Fragen → Vorschläge → Tour-Detail → Tagesablauf
├── Gruppen:     Programm → Gruppenwanderung → Anmelden
├── Meine Touren: Gespeichert → Navigation → Abkürzen / Heimweg
└── Hilfe:       Hilfe-Knopf → Notruf 112 → Tour teilen
```

### 5.1 Startseite
- Begrüßung, drei große Knöpfe. Darunter die nächste Gruppenwanderung als Karte (falls vorhanden).
- **Akzeptanz:** Ohne Konto nutzbar; alle Knöpfe ≥ 56 dp; bei 200 % Schrift keine Überläufe.

### 5.2 Fragen (Suche)
- Oben immer sichtbar: „Start: Naturfreundehaus Veitshöchheim · ändern“ (bzw. Bahnhof). Beim allerersten Start ist die Startpunkt-Wahl ein eigener Bildschirm mit zwei großen Karten.
- Frage 1 „Wie möchten Sie wandern?“ → drei große Karten mit Bild + Satz:
  - „Rundweg ab Veitshöchheim – ohne Bus und Bahn“ (`loop`)
  - „Loslaufen und mit Bus/Bahn zurück“ (`walk_out_ride_back`)
  - „Mit Bus/Bahn hin, wandern, mit Bus/Bahn zurück“ (`ride_both_ways`)
  - „Egal“
- Frage 2 „Wie lange möchten Sie gehen?“ → bis 2 Std. / 2–4 Std. / länger
- Frage 3 „Wie anstrengend?“ → leicht / mittel / egal
- Frage 4 „Möchten Sie unterwegs einkehren?“ → „Ja, mit Einkehr“ / „Egal“ (nur Touren mit Einkehr, die am gewählten Tag geöffnet hat, wenn ein Datum gewählt ist)
- Nur bei `ride_both_ways`: Zusatzfrage „Wie lange höchstens fahren (einfach)?“ → bis 30 / 60 / 90 Min.
- Jede Frage ein eigener Bildschirm, Knopf „Weiter“, „Zurück“ möglich. Option „Alle Touren zeigen“ überspringt die Fragen.
- **Akzeptanz:** Filterlogik als reine Funktion mit Unit-Tests (alle Kombinationen Typ × Startpunkt).

### 5.3 Vorschläge
- 3–5 Ergebnisse als große Karten: Foto, Name, Tourenart (Symbol + Wort), Gehzeit, Schwierigkeit (Farbe + Wort), Fahrzeit gesamt (bei `loop`: „ohne Bus und Bahn“), Einkehr-Hinweis („Einkehr: Gasthaus X, km 6“).
- Bei 0 Treffern: „Keine passende Tour. Möchten Sie eine Frage ändern?“ + Knöpfe.

### 5.4 Tour-Detail
- Oben ein Kurzfazit-Satz (siehe Microcopy), dann Hauptknopf „Verbindung zeigen“.
- Darunter: Karte (Route, Start/Ziel, Haltestellen, POIs), Höhenprofil, eigener Block **„Einkehren“** (siehe 5.11), Liste „Unterwegs“ (WC, Bänke, Aussichtspunkte), Wegbeschaffenheit, Hinweise (z. B. „steiler Abstieg nach km 6“), Abkürzungsmöglichkeiten.
- Bei `loop` heißt der Hauptknopf „Tagesablauf zeigen“ statt „Verbindung zeigen“.
- Zweiter Knopf: „Für unterwegs speichern“.

### 5.5 Verbindung / Tagesablauf
- Datum (Standard: heute/nächster Samstag) und gewünschte Abfahrts- bzw. Losgehzeit.
- Darstellung als **senkrechter Tagesablauf** mit Uhrzeiten, je Schritt eine Zeile mit Symbol:

  ```
  09:10  Naturfreundehaus Veitshöchheim – zu Fuß 8 Min.
  09:18  Bahnhof Veitshöchheim – Zug RB … Richtung … (Gleis 1)
  09:41  Ankunft A – Wanderung beginnt
         Wanderung A → B, ca. 3 Std. inkl. Einkehr
  13:30  Einkehr: Gasthaus X (Ruhetag Montag)
  15:05  Haltestelle B – Bus 19 Richtung Würzburg
  15:40  Bahnhof Veitshöchheim – zu Fuß 8 Min. zum Naturfreundehaus
  ```
  (Beispiel; echte Werte aus dem TransitProvider.)
- `loop`: nur Fußweg-Zeilen + Einkehr. `walk_out_ride_back`: Wanderung, dann Rückfahrt. `ride_both_ways`: Hinfahrt zu A, Wanderung A → B, Rückfahrt von B.
- Die Rückfahrt wird aus der erwarteten Ankunftszeit am Ziel berechnet (Gehzeit + geplante Einkehrdauer, Standard 60 Min., änderbar). Zusätzlich 2–3 spätere Alternativen.
- **„Letzte Rückfahrt heute: 21:14“** immer gut sichtbar; Warnung, wenn die geplante Ankunft weniger als 60 Min. davor liegt.
- Ist der Startpunkt das Naturfreundehaus, wird der Fußweg zur nächsten sinnvollen Haltestelle (Bahnhof oder Bushaltestelle) automatisch vorangestellt/angehängt.
- Knopf „Im DB Navigator öffnen“ (Deep-Link, Fallback Web-Auskunft) und Hinweis „Mit Deutschlandticket fahren Sie ohne Extra-Ticket“ (Text konfigurierbar).
- Datenquelle je nach Stufe (Abschnitt 8). In Stufe 1 klarer Hinweis „Planmäßige Zeiten, ohne Verspätungen“.

### 5.6 Meine Touren / Gespeichert
- Liste gespeicherter Touren, Speicherstatus („Offline verfügbar“ / „Wird geladen 60 %“), Knopf „Wanderung starten“.

### 5.7 Navigation
- Karte folgt dem Standort, Route grün, gegangener Teil grau.
- Große Anzeige: Restdistanz bis Ziel und bis zum nächsten POI.
- **Abweichung:** > 40 m von der Route für > 20 s → Vibration + Sprachansage (`flutter_tts`, Deutsch) + Banner. Werte konfigurierbar.
- Bildschirm darf aus sein: Standort im Vordergrunddienst (Android Foreground Service mit Benachrichtigung „Navigation läuft“). Akku-sparend: Standort alle 5 s / 10 m.
- Knöpfe: „Ich möchte abkürzen“, „Pause“, „Wanderung beenden“.
- **Akzeptanz:** Abweichungslogik als reine Funktion mit Tests (Punkt-zu-Polylinie-Distanz).

### 5.8 Abkürzen / Heimweg
- Nächste 1–3 Haltestellen nach Fußweg-Entfernung, je mit Gehzeit und nächster Abfahrt.
- Knopf „Dorthin führen“ startet Fußnavigation zur Haltestelle.
- Am Tourende automatisch: „Nächste Rückfahrt ab [Haltestelle] um …, Fußweg 6 Min.“

### 5.9 Hilfe
- Großer roter Knopf „Notruf 112 anrufen“ (`tel:112`, mit Bestätigung).
- „Meinen Standort senden“: öffnet Teilen-Dialog (SMS/WhatsApp) mit Text + Kartenlink (`geo:` und https-Link). Kein Server beteiligt.
- „Tour mit Angehörigen teilen“: Link zur Tour.
- Kontakt der Tourenleitung (bei Gruppenwanderungen): Anrufen-Knopf.
- Einstellungen: Schriftgröße, Hochkontrast, Startort, Sprachansagen an/aus. Impressum, Datenschutz, Konto löschen.

### 5.10 Gruppen
- Programm: kommende Gruppenwanderungen (Datum, Tour, Treffpunkt, Tourenleitung, freie Plätze).
- Detail: Treffpunkt mit Karte, Uhrzeit, Ticket-Hinweis, Ausrüstung, Kosten (Mitglieder frei, Gäste Betrag konfigurierbar).
- Anmelden: Konto per Telefonnummer + SMS-Code, Name. Ein Tipp „Verbindlich anmelden“. Abmelden mit Bestätigung.
- Mitteilungen der Tourenleitung als Push-Benachrichtigung + Liste im Detail.

### 5.11 Einkehrmöglichkeiten
- Im Tour-Detail eigener Block „Einkehren“: je Lokal Name, Art (Gasthaus, Häckerwirtschaft, Café, Hütte, Biergarten), Lage auf der Tour („bei km 6“ oder „am Ziel“), Umweg zu Fuß, Ruhetag/Öffnungszeiten, Telefon („Anrufen“-Knopf zum Reservieren), Hinweis „saisonal“ (z. B. Häckerwirtschaften nur zeitweise geöffnet).
- Auf der Karte eigenes, gut erkennbares Symbol mit Beschriftung.
- Mit gewähltem Datum: Anzeige „Am Samstag geöffnet“ / „Am Montag Ruhetag“ (grün/grau + Text). Unbekannte Zeiten: „Öffnungszeiten bitte vorher prüfen“.
- Navigation: Hinweis „In 300 m: Gasthaus X“.
- Datenquelle: von der Tourenleitung gepflegt; Vorschläge aus OpenStreetMap (`amenity=restaurant|cafe|pub|biergarten`, `opening_hours`) per Import-Skript, Übernahme nur nach Bestätigung.
- **Akzeptanz:** Öffnungslogik (Wochentag, Ruhetag, Saisonzeitraum) als reine Funktion mit Tests.

### 5.12 Tourenleitung (App + Web)
- Tour anlegen: GPX hochladen → Länge, Höhenmeter, Profil automatisch berechnen; Gehzeit nach DIN 33466 (Wanderzeit-Formel) vorschlagen, manuell überschreibbar. Felder: Name, Beschreibung, Tourenart, Startpunkt(e), Schwierigkeit, Start-Haltestelle A / Ziel-Haltestelle B (Auswahl aus Haltestellenliste, je nach Tourenart), Einkehr (aus Liste wählen oder neu anlegen), POIs, Fotos, Hinweise.
- Plausibilitätsprüfung: Bei `ride_both_ways` müssen A und B gesetzt sein; bei `walk_out_ride_back` B; bei `loop` muss die Route nahe dem Startpunkt beginnen und enden (≤ 300 m).
- Gruppenwanderung ausschreiben: Tour wählen, Datum/Uhrzeit, Treffpunkt, max. Teilnehmende, Hinweistext.
- Teilnehmerliste, „Mitteilung an alle“, „Absagen“ (sendet Push).

## 6. Datenmodell (Postgres + PostGIS, Supabase)

```
profiles        (id uuid PK = auth.uid, display_name, phone, role enum[member,tour_leader,admin], created_at)
start_points    (id text PK ['nfh_vhh','bf_vhh'], name, address, location geometry(Point,4326),
                 nearest_stop_ids text[], walk_min_to_stop jsonb)   -- Fußwege zu den nächsten Haltestellen
tours           (id, slug, name, description, tour_type enum[loop,walk_out_ride_back,ride_both_ways],
                 start_point_ids text[],            -- für welche Startpunkte die Tour passt (loop/walk_out)
                 difficulty enum[easy,medium,hard], distance_m, ascent_m, descent_m,
                 duration_min, surface_notes, warnings, route geometry(LineString,4326),
                 stop_a_id,                          -- nur ride_both_ways: Haltestelle am Wanderbeginn
                 stop_b_id,                          -- walk_out_ride_back + ride_both_ways: Haltestelle am Wanderende
                 has_food bool,                      -- abgeleitet aus tour_food
                 scenery enum[normal,nice,outstanding], -- landschaftliche Bewertung (Abschnitt 18)
                 is_demo bool, published bool, updated_at, created_by)
tour_elevation  (tour_id, profile jsonb)            -- [{d_m, ele_m}], vorberechnet
pois            (id, tour_id, kind enum[wc,bench,viewpoint,shortcut,info], name, note, location geometry(Point,4326))
food_places     (id, name, kind enum[gasthaus,haeckerwirtschaft,cafe,huette,biergarten,other], phone, website,
                 location geometry(Point,4326), opening_hours text,  -- OSM-Syntax
                 rest_days int[],                    -- 1=Mo … 7=So
                 season_from date, season_to date,   -- optional, z. B. Häcker
                 osm_id, verified_at, note)
tour_food       (tour_id, food_place_id, at_km numeric, detour_min int, position enum[on_route,at_end,at_start])
tour_photos     (id, tour_id, storage_path, caption, sort)
stops           (id = zHV/DHID, name, location geometry(Point,4326))   -- aus zHV/GTFS importiert, nur Region
tour_transit    (tour_id, direction enum[to,from], stop_id, lines text[], headway_note, walk_min, note,
                 ride_min int, transfers int)  -- Stufe 1, gepflegt; Fahrzeit und Umstiege (Abschnitt 18)
group_hikes     (id, tour_id, starts_at timestamptz, meeting_point text, meeting_location geometry(Point,4326),
                 leader_id, max_participants, guest_fee_cents, notes, status enum[planned,cancelled,done])
registrations   (group_hike_id, profile_id, created_at, PK(group_hike_id, profile_id))
announcements   (id, group_hike_id, author_id, text, created_at)
```

- **RLS:** Öffentlich lesbar: `tours/pois/tour_photos/stops/tour_transit` mit `published = true`, `group_hikes`. Schreiben nur `tour_leader`/`admin`. `registrations`: eigene Zeilen; Tourenleitung liest die Zeilen ihrer Gruppenwanderungen. Telefonnummern nur für `tour_leader` der jeweiligen Wanderung sichtbar.
- Migrationen in `supabase/migrations/`, Seed in `supabase/seed.sql` (nur Demo-Daten mit `is_demo = true`).

## 7. Architektur

### App
- **Flutter** (stable), Dart null-safe. Android zuerst (minSdk 26), iOS später aus derselben Codebasis; Web-Build für Tourenleitung.
- State: `flutter_riverpod`. Routing: `go_router`. Lokale DB: `drift` (SQLite). Netzwerk: `supabase_flutter`, `dio` für externe APIs.
- Karte: `maplibre_gl` (Vektorkacheln). Standort: `geolocator`. Sprache: `flutter_tts`. Teilen: `share_plus`. Anrufe/Links: `url_launcher`. Push: `firebase_messaging` (nur FCM-Token, keine Analytics).
- Lokalisierung: `flutter_localizations` + ARB-Dateien (`lib/l10n/app_de.arb`); keine fest verdrahteten Texte.
- Ordnerstruktur nach Features: `lib/features/{search,tour,transit,navigation,offline,groups,help,leader,settings}/` mit `data/ domain/ ui/`.

### Austauschbare Anbieter (Interfaces in `lib/core/providers/`)
```dart
abstract class TransitProvider {
  Future<List<Journey>> journeys({required StopRef from, required StopRef to,
      required DateTime time, bool arriveBy = false});
  Future<List<Departure>> departures(StopRef stop, DateTime from);
  Future<List<StopRef>> nearbyStops(LatLng point, {int maxWalkMin = 20});
}
abstract class WalkRoutingProvider { Future<WalkRoute> route(LatLng from, LatLng to); }
abstract class WeatherProvider { Future<Forecast> forecast(LatLng p, DateTime day); }
```
Implementierungen: `Mock*` (für Tests und Demo, Standard in Debug), `Static*` (Stufe 1), später `Motis*`/`Trias*`. Auswahl per `--dart-define=TRANSIT_PROVIDER=...`.

### Backend
- **Supabase**, Region EU (Frankfurt): Postgres+PostGIS, Auth (Telefon-OTP), Storage (Fotos, GPX), Edge Functions (GPX-Verarbeitung, Push-Versand, später TRIAS-Proxy, damit API-Schlüssel nie in der App liegen).
- Keine Secrets im Repo. Konfiguration per `--dart-define` aus GitHub Secrets.

## 8. ÖPNV-Daten (stufenweise)

| Stufe | Quelle | Inhalt | Voraussetzung |
|---|---|---|---|
| 1 (MVP) | Haltestellen aus **zHV** bzw. **DELFI-GTFS** (Open-Data-ÖPNV, kostenlos, Registrierung) – nur Region importieren. Pro Tour gepflegte `tour_transit`-Angaben (Haltestelle, Linien, Takt, Fußweg). Fahrtzeiten: Absprung in DB Navigator / Web-Auskunft | Planmäßige Infos, keine Echtzeit | Registrierung Open-Data-Portal |
| 2 | Journey-Planner auf Basis GTFS: z. B. öffentliche MOTIS-Instanz (Transitous) **oder** selbst gehostetes MOTIS/OpenTripPlanner mit DELFI-GTFS | Echte Verbindungen (Soll-Fahrplan) in der App | Nutzungsbedingungen prüfen bzw. Server |
| 3 | **TRIAS**-Schnittstelle über die Bayerische Eisenbahngesellschaft (BEG) | Verbindungen mit Echtzeit/Verspätungen | Vertrag mit BEG |

- Claude Code: **Deep-Link-Format für DB Navigator und Web-Auskunft aktuell recherchieren**, nicht raten; in `lib/features/transit/data/deeplinks.dart` kapseln, mit Fallback auf die Web-Auskunft.
- GTFS-Import als Skript `tools/import_stops.dart` (oder Python), filtert per Bounding-Box auf Landkreise Würzburg/Main-Spessart/Kitzingen und Stadt Würzburg.

## 9. Karten & Offline

- Vektorkacheln auf Basis OpenStreetMap über einen Kartenanbieter mit App-tauglichen Bedingungen oder selbst gehostet (PMTiles). **Nicht** die OSM-Standardkacheln (tile.openstreetmap.org) verwenden. Style-URL und Schlüssel per `--dart-define`.
- Attribution „© OpenStreetMap-Mitwirkende“ immer sichtbar.
- Offline speichern: Kartenausschnitt (Bounding-Box der Route + 1 km, Zoom 10–16) über MapLibre Offline-Regionen, Tourdaten + POIs + Haltestellen + Fotos in Drift. Speichergröße vorher anzeigen („ca. 25 MB“), nur im WLAN als Standard.
- Fußwege-Routing (Abkürzen/zur Haltestelle): openrouteservice oder GraphHopper (Profil Wandern) via Edge Function; offline Fallback: Luftlinie + Hinweis.

## 10. Datenschutz & Sicherheit

- DSGVO: Datenminimierung, Hosting in der EU, Auftragsverarbeitungsvertrag mit Anbietern.
- Standort wird **nur auf dem Gerät** verarbeitet. Teilen nur aktiv durch Nutzende.
- Kein Analytics/Crash-Tracking mit personenbezogenen Daten (Crash-Reports nur mit Einwilligung).
- Konto löschen in der App (löscht `profiles` + `registrations`).
- Bildschirme Impressum und Datenschutzerklärung (Texte liefert der Verein; Platzhalter).
- Berechtigungen nur bei Bedarf und mit erklärendem Vorab-Bildschirm („Damit die Karte zeigt, wo Sie sind …“).

## 11. Demo-/Seed-Daten

- 3 Demo-Touren mit `is_demo = true`, **je eine pro Tourenart** (`loop`, `walk_out_ride_back`, `ride_both_ways` mit A ≠ B), jeweils mit mindestens einer Demo-Einkehr; Geometrien aus Test-GPX in `assets/demo/` (selbst erstellt, plausibel, als Demo gekennzeichnet).
- Die zwei Startpunkte als feste Seed-Einträge in `start_points`.
- Platzhalter für Natura Trail „Höhfeldplatte“ ohne Geometrie, bis der Verein die GPX liefert.
- Treffpunkt Naturfreundehaus: Adresse wie oben; Koordinaten **nicht erfinden** – per Geocoding ermitteln oder vom Verein bestätigen lassen.

## 12. Build & CI

- GitHub Actions `.github/workflows/build.yaml`: bei Push auf `main` und manuell (`workflow_dispatch`):
  1. Flutter stable einrichten, `flutter pub get`
  2. `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test`
  3. `flutter build apk --release` mit `--dart-define`s aus Secrets
  4. APK als Artefakt hochladen (herunterladbar aus dem Actions-Lauf)
- Signierung: Keystore als Base64-Secret; ohne Secret Debug-Signatur.
- Später: `flutter build appbundle`, iOS-Build, Flutter-Web-Deploy für Tourenleitung.

## 13. Tests & Qualität

- Unit-Tests: Filterlogik, Gehzeitberechnung (DIN 33466), Abweichungserkennung, GPX-Parser, Restdistanz.
- Widget-Tests für jeden Bildschirm, zusätzlich bei `textScaler` 2.0.
- Barrierefreiheits-Tests: `meetsGuideline(androidTapTargetGuideline)`, `textContrastGuideline`, `labeledTapTargetGuideline`.
- Integrationstest: Suche → Detail → Speichern → Navigation (mit Mock-Standort).
- Lint: `flutter_lints` streng.

## 14. Meilensteine (in dieser Reihenfolge)

| # | Inhalt | Fertig, wenn … |
|---|---|---|
| M0 | Projekt-Setup, Ordnerstruktur, Theme, l10n, go_router mit 4 Bereichen, CI-Workflow | APK wird in GitHub Actions gebaut; leere Bereiche navigierbar |
| M1 | Startpunkt-Wahl, Tourenarten, Tourenliste, Fragen-Suche, Tour-Detail mit Mock-Daten, Höhenprofil, Einkehr-Block mit Öffnungslogik | Suche liefert erwartete Treffer für alle Typ × Startpunkt-Kombinationen (Tests), Detail zeigt Kurzfazit und Einkehr |
| M2 | Karte (MapLibre) im Detail, Offline-Speichern, Drift | Gespeicherte Tour öffnet im Flugmodus mit Karte |
| M3 | Navigation unterwegs inkl. Abweichungswarnung, Sprachansage, Vordergrunddienst | Mit simuliertem GPS-Track korrekte Warnungen |
| M4 | ÖV Stufe 1: Haltestellen-Import, `tour_transit`, Tagesablauf-Bildschirm für alle drei Tourenarten, Fußweg Naturfreundehaus ↔ Haltestelle, Deep-Links, Abkürzen/Heimweg | Für jede Demo-Tour korrekter Tagesablauf (0/1/2 Fahrten) + funktionierender Absprung |
| M5 | Supabase: Schema, RLS, Auth per SMS, Gruppenwanderungen, Anmeldung, Push | Anmelden/Abmelden funktioniert, RLS-Tests grün |
| M6 | Tourenleitung (Web + App): GPX-Import, Tour anlegen, Ausschreiben, Mitteilung | Neue Tour erscheint nach Freigabe in der App |
| M7 | Hilfe-Bereich, Einstellungen, Datenschutz, Feinschliff Barrierefreiheit | Alle a11y-Tests grün, 200 % Schrift ohne Überlauf |
| M8 | Vorbereitung Pilot: Testanleitung für Senioren-Tests (`docs/usability-test.md`), Fehlerbehebung | APK an Testgruppe verteilbar |

Nach jedem Meilenstein: `CHANGELOG.md` aktualisieren, offene Annahmen in `DECISIONS.md`.

## 15. Definition of Done (für jede Funktion)

- Erfüllt die UX-Regeln aus Abschnitt 4
- Texte in ARB, keine fest verdrahteten Strings
- Tests vorhanden und grün, `flutter analyze` ohne Warnungen
- Funktioniert offline oder zeigt einen verständlichen Hinweis
- Keine Secrets im Code

## 16. Offene Punkte (vom Verein zu klären)

- Endgültiger App-Name, Paketname, Logo/Farben (Markenrechte NaturFreunde klären)
- Ansprechperson und Freigabe durch die Ortsgruppe
- Bestehende Touren als GPX (inkl. Natura Trail Höhfeldplatte), Fotos, Beschreibungen
- Wer betreibt Backend und Kartenanbieter, Budget für laufende Kosten
- Datenschutzerklärung und Impressum
- Gastgebühr und Anmeldebedingungen für Gruppenwanderungen
- Antrag Open-Data-ÖPNV (Stufe 1) und ggf. Vertrag BEG (Stufe 3)

## 17. Quellen

- NaturFreunde Veitshöchheim/Würzburg – Wandern: https://www.naturfreunde-wuerzburg.de/unsere-aktivitaeten/wandern
- Gemeinde Veitshöchheim – Lage & Anreise: https://www.gemeinde-veitshoechheim.de/unser-ort/zahlen-fakten/lage-anreise
- BayernInfo – ÖPNV-Daten (GTFS/NeTEx, zHV, TRIAS): https://www.bayerninfo.de/en/about-bayerninfo-1/data-offer/public-transport-data
- Konzeptdokument (Claude Docs): https://claude.ai/code/artifact/9e6c3a61-2ac0-4284-aea6-dc233c7ee930

## 18. Änderungen nach Rückmeldung des Vereins (03.10.2026)

Diese Punkte ergänzen bzw. ändern Abschnitt 5.2/5.3:

1. **Längere Touren:** Vorschläge bis ca. 15–20 km, je nach Höhenprofil. Regel: Strecke ≤ 20 km **und** km + Höhenmeter bergauf / 100 ≤ 20 („Leistungskilometer“; z. B. 20 km flach, 18 km mit 200 Hm, 15 km mit 500 Hm). Antwort „länger“ bei der Gehzeit: „Länger als 4 Stunden (bis ca. 20 km)“. „Alle Touren zeigen“ zeigt auch längere Touren.
2. **Einkehr eher am Schluss:** Touren mit Einkehr am Ziel oder im letzten Drittel (bzw. in den letzten 2 km) werden bevorzugt; die Vorschlagskarte nennt diese Einkehr. Im Tagesablauf (5.5) wird die Einkehr standardmäßig ans Ende gelegt.
3. **Landschaftlich schöne Strecken bevorzugen:** Feld `scenery` (normal / schön / besonders schön), gepflegt von der Tourenleitung; wird auf Karte und Detail als Text angezeigt und zählt am stärksten in der Rangfolge.
4. **Auch weiter weg:** Anfahrt mit Bus/Bahn standardmäßig bis 60 Min. (einfache Fahrt inkl. Fußweg vom Startpunkt), gilt für alle Touren mit Fahrten; Verbindungen **ohne Umsteigen** werden bevorzugt, mehrfaches Umsteigen nach hinten gereiht. Die Fahrzeit-Frage hat „bis 60 Minuten“ vorausgewählt.

Rangfolge der Vorschläge (Gewichte als Konstanten in `SuggestionRules`): Landschaft > Einkehr am Schluss > ohne Umsteigen; bei Gleichstand kürzere Gehzeit.

