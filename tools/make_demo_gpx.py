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
    "demo_long_ride": {
        "name": "DEMO Karlstadt – Gambach (Maintalhöhen)",
        "waypoints": [
            (49.9600, 9.7720, 165), (49.9680, 9.7850, 260),
            (49.9790, 9.7900, 320), (49.9900, 9.7820, 340),
            (50.0010, 9.7700, 330), (50.0080, 9.7520, 300),
            (50.0020, 9.7380, 250), (49.9930, 9.7330, 290),
            (49.9820, 9.7200, 330), (49.9720, 9.7300, 300),
            (49.9700, 9.7480, 260), (49.9790, 9.7560, 230),
            (49.9850, 9.7450, 230), (49.9890, 9.7560, 170),
        ],
    },
    "demo_far_transfer": {
        "name": "DEMO Spessart-Rundblick",
        "waypoints": [
            (50.0500, 9.7000, 160), (50.0560, 9.7150, 280),
            (50.0650, 9.7200, 380), (50.0740, 9.7100, 400),
            (50.0760, 9.6900, 360), (50.0680, 9.6750, 300),
            (50.0580, 9.6800, 220), (50.0520, 9.6950, 165),
        ],
    },
    "demo_too_long": {
        "name": "DEMO Große Weinbergrunde",
        "waypoints": [
            (49.8300, 9.8820, 180), (49.8450, 9.8700, 230),
            (49.8650, 9.8600, 260), (49.8850, 9.8450, 240),
            (49.9000, 9.8300, 220), (49.9050, 9.8600, 250),
            (49.8900, 9.8900, 270), (49.8700, 9.9050, 240),
            (49.8500, 9.9100, 220), (49.8380, 9.9000, 200),
            (49.8300, 9.8820, 180),
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
