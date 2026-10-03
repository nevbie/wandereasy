#!/usr/bin/env python3
"""Erzeugt die Demo-GPX-Dateien in assets/demo/ (SPEC 11).

Die Routen sind SYNTHETISCH: geglättete Linien zwischen ungefähren
Wegpunkten im Raum Veitshöchheim mit erfundenem, plausiblem Höhenverlauf.
Sie dienen nur zum Entwickeln und Testen und sind KEINE echten Wanderwege.

Aufruf: python3 tools/make_demo_gpx.py
"""
import math
import os

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "demo")

# Ungefähre Wegpunkte (lat, lon) und Höhen (m) – nur Demo.
TOURS = {
    "demo_loop": {
        "name": "DEMO Rundweg Veitshöchheim",
        "waypoints": [
            (49.8300, 9.8820, 180), (49.8360, 9.8760, 230),
            (49.8430, 9.8780, 290), (49.8470, 9.8890, 300),
            (49.8420, 9.8990, 270), (49.8350, 9.8950, 210),
            (49.8300, 9.8820, 180),
        ],
    },
    "demo_walk_out": {
        "name": "DEMO Veitshöchheim – Thüngersheim",
        "waypoints": [
            (49.8300, 9.8820, 180), (49.8400, 9.8700, 240),
            (49.8520, 9.8620, 300), (49.8640, 9.8560, 290),
            (49.8750, 9.8480, 230), (49.8830, 9.8420, 185),
        ],
    },
    "demo_ride_both": {
        "name": "DEMO Retzbach – Thüngersheim",
        "waypoints": [
            (49.9060, 9.8170, 175), (49.9120, 9.8020, 250),
            (49.9050, 9.7900, 320), (49.8960, 9.8020, 335),
            (49.8930, 9.8250, 330), (49.8880, 9.8390, 300),
            (49.8830, 9.8420, 185),
        ],
    },
}

STEP_M = 40


def dist(a, b):
    r = 6371000
    p1, p2 = math.radians(a[0]), math.radians(b[0])
    dp, dl = p2 - p1, math.radians(b[1] - a[1])
    h = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(h))


def densify(wps):
    pts = []
    for i in range(len(wps) - 1):
        a, b = wps[i], wps[i + 1]
        n = max(1, int(dist(a, b) / STEP_M))
        for k in range(n):
            t = k / n
            # leichte Schlängelung, damit es nicht wie ein Lineal aussieht
            wiggle = 0.00025 * math.sin(t * math.pi * 3) * math.sin(t * math.pi)
            lat = a[0] + (b[0] - a[0]) * t + wiggle
            lon = a[1] + (b[1] - a[1]) * t - wiggle
            # Höhe weich (Kosinus) zwischen den Wegpunkten
            s = (1 - math.cos(t * math.pi)) / 2
            ele = a[2] + (b[2] - a[2]) * s
            pts.append((lat, lon, ele))
    pts.append(wps[-1])
    return pts


def main():
    os.makedirs(OUT, exist_ok=True)
    for key, tour in TOURS.items():
        pts = densify(tour["waypoints"])
        lines = [
            '<?xml version="1.0" encoding="UTF-8"?>',
            '<gpx version="1.1" creator="tools/make_demo_gpx.py" '
            'xmlns="http://www.topografix.com/GPX/1/1">',
            "  <metadata><name>%s</name>"
            "<desc>DEMO-DATEN – synthetisch, kein echter Wanderweg</desc>"
            "</metadata>" % tour["name"],
            "  <trk><name>%s</name><trkseg>" % tour["name"],
        ]
        for lat, lon, ele in pts:
            lines.append(
                '    <trkpt lat="%.6f" lon="%.6f"><ele>%.1f</ele></trkpt>'
                % (lat, lon, ele)
            )
        lines += ["  </trkseg></trk>", "</gpx>", ""]
        with open(os.path.join(OUT, key + ".gpx"), "w", encoding="utf-8") as f:
            f.write("\n".join(lines))
        total = sum(dist(pts[i], pts[i + 1]) for i in range(len(pts) - 1))
        print("%s: %d Punkte, %.1f km" % (key, len(pts), total / 1000))


if __name__ == "__main__":
    main()
