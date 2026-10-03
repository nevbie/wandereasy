#!/usr/bin/env python3
"""Übernimmt Referenz-Routen (GPX) als Touren in assets/tours/.

- Schreibt je Route eine bereinigte GPX-Datei (nur Track mit Höhe; ohne
  Zeitstempel, Wegpunkte und Metadaten des Quell-Dienstes).
- Ordnet Wegpunkte (Highlights) der Route zu (km-Position) und übersetzt sie
  mit der Tabelle unten in kurze deutsche Namen.
- Schreibt assets/tours/tours.json.

Fahrzeiten, Umstiege und Öffnungszeiten werden NICHT erfunden; sie bleiben
leer, bis sie gepflegt bzw. berechnet werden (M4).

Aufruf: python3 tools/import_reference_gpx.py <ordner-mit-gpx>
"""
import json
import math
import os
import sys
import xml.etree.ElementTree as ET

NS = {"g": "http://www.topografix.com/GPX/1/1"}
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "tours")

SOURCE_NOTE = "Referenz-Route (in komoot geplant) – vor Veröffentlichung prüfen"

# Je Route: Schlüssel = Anfang des Dateinamens (nach dem Datumspräfix).
# Wegpunkte: Originalname -> (Art, deutscher Name) oder None = weglassen.
# Art: viewpoint, bench, info, wc, food:<FoodKind>.
# ANNAHME: Schwierigkeit und Landschaft sind Vorschläge aus den Daten
# (Länge, Höhenmeter, Aussichtspunkte); die Tourenleitung bestätigt sie.
ROUTES = {
    "View_of_the_Main_Valley___Rottenbauer": dict(
        id="ref_winterhausen_steinkreis",
        name="Winterhausen: Maintalblick und Steinkreis",
        place="Winterhausen",
        scenery="outstanding",
        description="Rundweg ab Winterhausen hinauf auf die Höhe mit mehreren "
        "Aussichtspunkten über das Maintal und Eibelstadt, vorbei an alten "
        "Steinbruchgebäuden und einem Steinkreis.",
        wpts={
            "Natura 2000 Information Board – Natural Treasures": ("info", "Natura-2000-Infotafel"),
            "Picnic area with a view of Winterhausen": ("bench", "Rastplatz mit Blick auf Winterhausen"),
            "View of Eibelstadt and the Main Valley": ("viewpoint", "Blick auf Eibelstadt und das Maintal"),
            "View of the Main Valley": ("viewpoint", "Blick ins Maintal"),
            "Ruins of Quarry Buildings": ("info", "Ruinen alter Steinbruchgebäude"),
            "Rottenbauer Stone Circle": ("info", "Steinkreis bei Rottenbauer"),
            "Muschelkalkweg": ("info", "Muschelkalkweg"),
        },
    ),
    "Seelein_Nature_Monument___Marian": dict(
        id="ref_vhh_seelein_ravensburg",
        name="Veitshöchheim: Seelein, Ravensburg und Weinberge",
        place="Veitshöchheim",
        scenery="outstanding",
        description="Rundweg ab Veitshöchheim zum Naturdenkmal Seelein und zur "
        "Ruine Ravensburg, zurück durch die Weinberge mit vielen Blicken auf "
        "Main und Maintal.",
        wpts={
            "Gebranntes Hölzlein": ("info", "Gebranntes Hölzlein"),
            "Seelein Nature Monument": ("info", "Naturdenkmal Seelein"),
            "View of the Main Valley Vineyards": ("viewpoint", "Blick auf die Weinberge im Maintal"),
            "View of the Silvaner vineyards and Main Valley": ("viewpoint", "Blick auf Silvaner-Weinberge und Maintal"),
            "Ravensburg Ruins and View of the Main Valley": ("viewpoint", "Ruine Ravensburg mit Blick ins Maintal"),
            "Rest Area with View of the Main River and Lock": ("bench", "Rastplatz mit Blick auf Main und Schleuse"),
            "Marian Shrine in the Vineyard": ("info", "Marienbildstock im Weinberg"),
            "View of the Main River from the vineyards": ("viewpoint", "Blick vom Weinberg auf den Main"),
            "View of the Main River and Vineyards": ("viewpoint", "Blick auf Main und Weinberge"),
        },
    ),
    "W_rzburger_Gate___Waldesruh": dict(
        id="ref_thuengersheim_hoehfeldplatte",
        name="Thüngersheim: Höhfeldplatte und Schutzhütte Waldesruh",
        place="Thüngersheim",
        scenery="nice",
        description="Rundweg ab dem Ortskern Thüngersheim (Würzburger Tor) "
        "hinauf zur Höhfeldplatte mit Blick ins Maintal, zurück über die "
        "Schutzhütte Waldesruh.",
        wpts={
            "Würzburger Gate": ("info", "Würzburger Tor"),
            "Hirtentor (Shepherd's Gate), Thüngersheim": ("info", "Hirtentor"),
            "View of the Main Valley from Höhfeldplatte Shelter": ("viewpoint", "Blick ins Maintal an der Schutzhütte Höhfeldplatte"),
            "View of the quarry at Höhfeldplatte and Scharlachberg Nature Reserve": ("viewpoint", "Blick auf den Steinbruch an der Höhfeldplatte"),
            "Höhfeldplatte and Scharlachberg Nature Reserve": ("info", "Naturschutzgebiet Höhfeldplatte und Scharlachberg"),
            "Waldesruh Shelter": ("bench", "Schutzhütte Waldesruh"),
        },
    ),
    "The_Moon_Watcher_Sculpture": dict(
        id="ref_winterhausen_mondweg",
        name="Winterhausen: Mondweg und Steinbruch",
        place="Winterhausen",
        scenery="nice",
        description="Rundweg ab Winterhausen auf dem Mondweg durch einen "
        "Hohlweg in die Weinberge, vorbei an Skulpturen und einem alten "
        "Steinbruch, zurück durch das Maintal.",
        wpts={
            "Inauguration stone of the Mondweg Winterhausen": ("info", "Gedenkstein Mondweg"),
            "Hollow Way and Tunnel in Winterhausen": ("info", "Hohlweg und Tunnel"),
            "Bench with a view of the Winterhausen vineyards and Waiting Girl sculpture": ("bench", "Bank mit Blick auf die Weinberge"),
            "The Moon Watcher Sculpture": ("info", "Skulptur am Mondweg"),
            "Steinbruch NOSW Stone Circle": ("info", "Steinkreis am Steinbruch"),
            "Quarry near Winterhausen": ("info", "Steinbruch bei Winterhausen"),
            "Quarry Canteen and Beer Cellar Ruins in Gossmannsdorf": ("info", "Ruinen von Steinbruchkantine und Bierkeller"),
            "Russian Grave Memorial": ("info", "Gedenkstätte Russengrab"),
        },
    ),
    "Veitsh_chheim_Palace___Seelein": dict(
        id="ref_vhh_schloss_seelein",
        name="Veitshöchheim: Schlossgarten und Seelein",
        place="Veitshöchheim",
        scenery="nice",
        description="Rundweg vom Schloss Veitshöchheim mit Hofgarten hinauf "
        "über dem Sendelbachtal zum Naturdenkmal Seelein und zurück.",
        warnings=["Kurzer schmaler Waldpfad (laut Planung „Jungle Path“) – bitte vorab prüfen."],
        wpts={
            "Spinario (Boy with Thorn) Statue": ("info", "Statue „Dornauszieher“"),
            "Putti Statues at the Castle Terrace": ("info", "Putten an der Schlossterrasse"),
            "Veitshöchheim Palace": ("info", "Schloss Veitshöchheim"),
            "Königspavillon Veitshöchheim": ("info", "Königspavillon"),
            "Hidden Path Above the Sendelbach Valley": ("info", "Pfad oberhalb des Sendelbachtals"),
            "Bench and information board at Seelein, Veitshöchheim": ("bench", "Bank und Infotafel am Seelein"),
            "Seelein Nature Monument": ("info", "Naturdenkmal Seelein"),
            "Jungle Path": ("info", "Schmaler Waldpfad"),
        },
    ),
    "View_of_Sommerhausen___Sommerhausen_Castle": dict(
        id="ref_winterhausen_sommerhausen",
        name="Winterhausen – Sommerhausen: Schneckenweg und Altstadt",
        place="Winterhausen",
        scenery="outstanding",
        description="Rundweg ab Winterhausen durch die Weinberge auf dem "
        "Skulpturenweg „Schneckenweg“ mit Blicken auf Sommerhausen, durch die "
        "Altstadt Sommerhausen und zurück.",
        wpts={
            "Pathway to the Vineyard": ("info", "Weg in den Weinberg"),
            "Snail Monument and View of Sommerhausen": ("viewpoint", "Schnecken-Denkmal mit Blick auf Sommerhausen"),
            "Oversized Bench With a View of Sommerhausen": ("bench", "Riesenbank mit Blick auf Sommerhausen"),
            "Schneckenweg Sculpture Trail": ("info", "Skulpturenweg „Schneckenweg“"),
            "View of Sommerhausen and the Main Valley Vineyards": ("viewpoint", "Blick auf Sommerhausen und die Weinberge"),
            "View of Sommerhausen": ("viewpoint", "Blick auf Sommerhausen"),
            "Viewpoint": ("viewpoint", "Aussichtspunkt"),
            "Sommerhausen Old Town": ("info", "Altstadt Sommerhausen"),
            "Sommerhausen Castle": ("info", "Schloss Sommerhausen"),
        },
    ),
    "View_of_Neuheiligenthal": dict(
        id="ref_bergtheim_dipbach",
        name="Bergtheim: Blick auf Dipbach und Neuheiligenthal",
        place="Bergtheim",
        scenery="nice",
        description="Fast ebener Rundweg ab Bergtheim über Feldwege zum Weiher "
        "mit Rastplatz, mit Blicken auf Dipbach und Neuheiligenthal.",
        wpts={
            "Pond with Picnic Area": ("bench", "Weiher mit Rastplatz"),
            "View of Dipbach": ("viewpoint", "Blick auf Dipbach"),
            "Old Sports Ground Dipbach": ("info", "Alter Sportplatz Dipbach"),
            "View of Neuheiligenthal": ("viewpoint", "Blick auf Neuheiligenthal"),
            "Bench at Trail Junction": ("bench", "Bank an der Wegkreuzung"),
        },
    ),
    "Main_Riverbank_Veitsh_chheim": dict(
        id="ref_vhh_mainufer_hofgarten",
        name="Veitshöchheim: Mainufer und Hofgarten",
        place="Veitshöchheim",
        scenery="nice",
        description="Rundweg durch den Hofgarten Veitshöchheim, am Mainufer "
        "entlang und über die Höhe zurück zum Schloss.",
        warnings=["Kurzer schmaler Waldpfad (laut Planung „Jungle Path“) – bitte vorab prüfen."],
        wpts={
            "Snail House (Grotto) in the Veitshöchheim Rococo Garden": ("info", "Grotte im Rokokogarten"),
            "Small Lake in the Hofgarten, Veitshöchheim": ("info", "Kleiner See im Hofgarten"),
            "Main Riverbank, Veitshöchheim": ("info", "Mainufer Veitshöchheim"),
            "Meegärtle Beer Garden": ("food:biergarten", "Meegärtle"),
            "Fisherman sculpture on the Main riverbank": ("info", "Fischer-Skulptur am Mainufer"),
            "Kneipp pool on the Main": ("info", "Kneippbecken am Main"),
            "Jungle Path": ("info", "Schmaler Waldpfad"),
            "Veitshöchheim Palace": ("info", "Schloss Veitshöchheim"),
        },
    ),
    "Chapel_at_Weingut_Schmitt": dict(
        id="ref_bergtheim_harfenspiel",
        name="Bergtheim: Weinbergkapelle Harfenspiel",
        place="Bergtheim",
        scenery="nice",
        description="Kurzer, fast ebener Rundweg ab Bergtheim zur Kapelle im "
        "Weinberg Harfenspiel mit Blick in die Weinberge.",
        wpts={
            "View of the Vineyard at Kapellenblick": ("viewpoint", "Blick in den Weinberg am Kapellenblick"),
            "Chapel of Our Lady in Harfenspiel Vineyard": ("info", "Kapelle im Weinberg Harfenspiel"),
            "Vineyard Grapes": None,
            "Fig Tree by the Chapel": None,
            "Chapel at Weingut Schmitt": None,  # dieselbe Kapelle
            "Chapel at Harfespiel": None,  # dieselbe Kapelle
            "Elderberry Plantation": ("info", "Holunderplantage"),
        },
    ),
}

# Startpunkt-Orte mit Veitshöchheim → Rundweg ab Startpunkt.
VEITSHOECHHEIM = "Veitshöchheim"


def dist(a, b):
    r = 6371000
    p1, p2 = math.radians(a[0]), math.radians(b[0])
    dp, dl = p2 - p1, math.radians(b[1] - a[1])
    h = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(h))


def stats(pts):
    total = asc = desc = 0.0
    ref = pts[0][2]
    for i in range(1, len(pts)):
        total += dist(pts[i - 1], pts[i])
        e = pts[i][2]
        if e - ref >= 3:
            asc += e - ref
            ref = e
        elif ref - e >= 3:
            desc += ref - e
            ref = e
    return total, asc, desc


def difficulty(km, asc):
    if km <= 10 and asc < 150:
        return "easy"
    if km + asc / 100 <= 14:
        return "medium"
    return "hard"


def along_km(pts, cum, wp):
    best = min(range(len(pts)), key=lambda i: dist(pts[i], wp))
    return round(cum[best] / 1000, 1), dist(pts[best], wp)


def main(folder):
    os.makedirs(OUT, exist_ok=True)
    tours, food_places = [], []
    for fname in sorted(os.listdir(folder)):
        if not fname.endswith(".gpx"):
            continue
        key = fname[fname.index("Download__") + 10:] if "Download__" in fname else fname
        cfg = next((v for k, v in ROUTES.items() if key.startswith(k)), None)
        if cfg is None:
            print("Übersprungen (keine Zuordnung):", fname)
            continue
        root = ET.parse(os.path.join(folder, fname)).getroot()
        pts = [
            (float(p.get("lat")), float(p.get("lon")), float(p.find("g:ele", NS).text))
            for p in root.iter("{%s}trkpt" % NS["g"])
        ]
        cum = [0.0]
        for i in range(1, len(pts)):
            cum.append(cum[-1] + dist(pts[i - 1], pts[i]))
        total, asc, desc = stats(pts)

        # Bereinigte GPX-Datei
        gpx_path = "assets/tours/%s.gpx" % cfg["id"]
        lines = [
            '<?xml version="1.0" encoding="UTF-8"?>',
            '<gpx version="1.1" creator="tools/import_reference_gpx.py" '
            'xmlns="http://www.topografix.com/GPX/1/1">',
            "  <metadata><name>%s</name><desc>%s</desc></metadata>" % (cfg["name"], SOURCE_NOTE),
            "  <trk><name>%s</name><trkseg>" % cfg["name"],
        ]
        lines += [
            '    <trkpt lat="%.6f" lon="%.6f"><ele>%.1f</ele></trkpt>' % p for p in pts
        ]
        lines += ["  </trkseg></trk>", "</gpx>", ""]
        with open(os.path.join(OUT, cfg["id"] + ".gpx"), "w", encoding="utf-8") as f:
            f.write("\n".join(lines))

        pois, food, seen = [], [], set()
        for w in root.iter("{%s}wpt" % NS["g"]):
            orig = w.find("g:name", NS).text
            if orig == cfg["place"] or orig == VEITSHOECHHEIM:
                continue  # Startort
            mapping = cfg["wpts"].get(orig, "missing")
            if mapping == "missing":
                print("  WARNUNG: Wegpunkt ohne Übersetzung:", orig)
                continue
            if mapping is None:
                continue
            kind, name = mapping
            km, off = along_km(pts, cum, (float(w.get("lat")), float(w.get("lon"))))
            if (name, km) in seen or name in {n for n, _ in seen} and kind != "viewpoint":
                continue
            seen.add((name, km))
            if kind.startswith("food:"):
                pid = "ref_food_" + "".join(
                    c for c in name.lower().replace("ä", "ae").replace("ö", "oe")
                    .replace("ü", "ue").replace("ß", "ss").replace(" ", "_")
                    if c.isascii())
                food_places.append(
                    dict(
                        id=pid,
                        name=name,
                        kind=kind.split(":")[1],
                        location=[float(w.get("lat")), float(w.get("lon"))],
                        note="Öffnungszeiten noch nicht erfasst",
                        isDemo=False,
                    )
                )
                food.append(
                    dict(placeId=pid, position="onRoute", atKm=km,
                         detourMin=0 if off < 60 else max(1, round(off / 70)))
                )
            else:
                pois.append(dict(kind=kind, name=name, atKm=km))

        km = total / 1000
        loop_from_vhh = cfg["place"] == VEITSHOECHHEIM
        tour = dict(
            id=cfg["id"],
            name=cfg["name"],
            description=cfg["description"],
            tourType="loop" if loop_from_vhh else "rideBothWays",
            startPointIds=["nfh_vhh", "bf_vhh"] if loop_from_vhh else [],
            difficulty=difficulty(km, asc),
            gpx=gpx_path,
            scenery=cfg["scenery"],
            warnings=cfg.get("warnings", []),
            food=food,
            pois=sorted(pois, key=lambda p: p["atKm"]),
            isDemo=False,
            sourceNote=SOURCE_NOTE,
        )
        if not loop_from_vhh:
            stop = dict(id="ref_stop_" + cfg["place"].lower().replace("ü", "ue"),
                        name=cfg["place"])
            tour["stopA"] = stop
            tour["stopB"] = stop
        tours.append(tour)
        print("%-55s %5.1f km +%3.0f m %s" % (cfg["name"], km, asc, tour["difficulty"]))

    with open(os.path.join(OUT, "tours.json"), "w", encoding="utf-8") as f:
        json.dump(
            {
                "_hinweis": "Referenz-Routen. Route und Höhen aus GPX (in komoot "
                "geplant), Wegpunkt-Namen übersetzt. Fahrzeiten, Umstiege und "
                "Öffnungszeiten sind noch NICHT erfasst. Vor Veröffentlichung "
                "von der Tourenleitung prüfen.",
                "foodPlaces": food_places,
                "tours": tours,
            },
            f,
            ensure_ascii=False,
            indent=2,
        )
        f.write("\n")


if __name__ == "__main__":
    main(sys.argv[1])
