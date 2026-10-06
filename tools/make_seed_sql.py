#!/usr/bin/env python3
"""Erzeugt supabase/seed.sql aus den Demo-Daten in assets/demo (tours.json + GPX).

So enthalten die Offline-Demo der App und der Datenbank-Seed immer dieselben Touren (SPEC 11).
In den Seed kommen nur Demo-Daten (is_demo = true) und die zwei Startpunkte.

Aufruf: python3 tools/make_seed_sql.py   (schreibt supabase/seed.sql neu; CI prüft, ob er aktuell ist)
"""
import json
import math
import pathlib
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parent.parent
DEMO = ROOT / "assets" / "demo"
OUT = ROOT / "supabase" / "seed.sql"
NS = {"g": "http://www.topografix.com/GPX/1/1"}

TOUR_TYPE = {"loop": "loop", "walkOutRideBack": "walk_out_ride_back", "rideBothWays": "ride_both_ways"}
POSITION = {"onRoute": "on_route", "atEnd": "at_end", "atStart": "at_start"}

# Wie lib/features/tour/domain/start_point.dart: Koordinaten bleiben null, bis der Verein sie bestätigt.
START_POINTS = [
    ("nfh_vhh", "Naturfreundehaus Veitshöchheim", 15),
    ("bf_vhh", "Bahnhof Veitshöchheim", 0),
]


def q(v):
    """SQL-Literal."""
    if v is None:
        return "null"
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return repr(v)
    if isinstance(v, list):
        return "array[" + ", ".join(q(x) for x in v) + "]::text[]" if v else "'{}'"
    return "'" + str(v).replace("'", "''") + "'"


def haversine(a, b):
    r = 6371000.0
    p1, p2 = math.radians(a[0]), math.radians(b[0])
    dp, dl = p2 - p1, math.radians(b[1] - a[1])
    h = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(h))


def read_gpx(path):
    root = ET.parse(path).getroot()
    pts = []
    for p in root.iterfind(".//g:trkpt", NS):
        ele = p.find("g:ele", NS)
        pts.append((float(p.get("lat")), float(p.get("lon")), float(ele.text) if ele is not None else 0.0))
    return pts


def metrics(pts):
    dist, up, down, profile = 0.0, 0.0, 0.0, [{"d_m": 0, "ele_m": round(pts[0][2], 1)}]
    for a, b in zip(pts, pts[1:]):
        dist += haversine(a, b)
        dz = b[2] - a[2]
        up += max(dz, 0)
        down += max(-dz, 0)
        profile.append({"d_m": round(dist), "ele_m": round(b[2], 1)})
    # Gehzeit nach DIN 33466: 4 km/h in der Ebene, 300 Hm/h bergauf, 500 Hm/h bergab;
    # die größere aus Horizontal- und Vertikalzeit plus die Hälfte der kleineren.
    horizontal = dist / 1000 / 4 * 60
    vertical = up / 300 * 60 + down / 500 * 60
    duration = max(horizontal, vertical) + min(horizontal, vertical) / 2
    return round(dist), round(up), round(down), round(duration), profile


def point_at_km(pts, km):
    """Interpolierte (lat, lon) bei [km] entlang der Spur."""
    target, done = km * 1000, 0.0
    for a, b in zip(pts, pts[1:]):
        step = haversine(a, b)
        if done + step >= target and step > 0:
            f = (target - done) / step
            return a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f
        done += step
    return pts[-1][0], pts[-1][1]


def point_sql(lat_lon):
    return f"extensions.st_setsrid(extensions.st_makepoint({lat_lon[1]:.6f}, {lat_lon[0]:.6f}), 4326)"


def main():
    data = json.loads((DEMO / "tours.json").read_text(encoding="utf-8"))
    lines = [
        "-- ERZEUGT von tools/make_seed_sql.py aus assets/demo – nicht von Hand ändern.",
        "-- Nur Demo-Daten (SPEC 11): erfundene Wege, Einkehren und Haltestellen, markiert mit is_demo.",
        "",
        "insert into public.start_points (id, name, walk_min_to_stop) values",
        ",\n".join(f"  ({q(i)}, {q(n)}, {q(json.dumps({'bf_vhh': w}))}::jsonb)" for i, n, w in START_POINTS) + ";",
        "",
    ]

    stops = {}
    for t in data["tours"]:
        for key in ("stopA", "stopB"):
            if key in t:
                stops[t[key]["id"]] = t[key]["name"]
    lines.append("insert into public.stops (id, name) values")
    lines.append(",\n".join(f"  ({q(i)}, {q(n)})" for i, n in stops.items()) + ";")
    lines.append("")

    lines.append(
        "insert into public.food_places (id, name, kind, opening_hours, rest_days, season_from, season_to, note, is_demo) values"
    )
    rows = []
    for f in data["foodPlaces"]:
        rest = "array[" + ", ".join(str(d) for d in f.get("restDays", [])) + "]::int[]" if f.get("restDays") else "'{}'"
        rows.append(
            f"  ({q(f['id'])}, {q(f['name'])}, {q(f['kind'])}, {q(f.get('openingHours'))}, {rest}, "
            f"{q(f.get('seasonFrom'))}, {q(f.get('seasonTo'))}, {q(f.get('note'))}, true)"
        )
    lines.append(",\n".join(rows) + ";")
    lines.append("")

    for t in data["tours"]:
        if not t.get("gpx") or t.get("isDemo") is False:
            continue  # echte Touren kommen von der Tourenleitung, nicht aus dem Seed
        pts = read_gpx(ROOT / t["gpx"])
        dist, up, down, duration, profile = metrics(pts)
        line = "extensions.st_setsrid(extensions.st_makeline(array[" + ", ".join(
            f"extensions.st_makepoint({p[1]:.6f}, {p[0]:.6f})" for p in pts
        ) + "]), 4326)"
        lines += [
            f"-- {t['name']}",
            "insert into public.tours (id, slug, name, description, tour_type, start_point_ids, difficulty, distance_m,",
            "  ascent_m, descent_m, duration_min, surface_notes, warnings, route, stop_a_id, stop_b_id, is_demo, published)",
            f"values ({q(t['id'])}, {q(t['id'].replace('_', '-'))}, {q(t['name'])}, {q(t.get('description', ''))},",
            f"  {q(TOUR_TYPE[t['tourType']])}, {q(t.get('startPointIds', []))}, {q(t['difficulty'])}, {dist}, {up}, {down}, {duration},",
            f"  {q(t.get('surfaceNotes'))}, {q(t.get('warnings', []))},",
            f"  {line},",
            f"  {q(t.get('stopA', {}).get('id'))}, {q(t.get('stopB', {}).get('id'))}, true, true);",
            "insert into public.tour_elevation (tour_id, profile) values",
            f"  ({q(t['id'])}, {q(json.dumps(profile, separators=(',', ':')))}::jsonb);",
        ]
        for p in t.get("pois", []):
            lines.append(
                f"insert into public.pois (tour_id, kind, name, note, location) values ({q(t['id'])}, {q(p['kind'])}, "
                f"{q(p['name'])}, {q(p.get('note'))}, {point_sql(point_at_km(pts, p['atKm']))});"
            )
        for f in t.get("food", []):
            lines.append(
                f"insert into public.tour_food (tour_id, food_place_id, at_km, detour_min, position) values ({q(t['id'])}, "
                f"{q(f['placeId'])}, {q(f.get('atKm'))}, {q(f.get('detourMin'))}, {q(POSITION[f['position']])});"
            )
        ride = t.get("ride", {})
        if "stopA" in t:
            lines.append(
                "insert into public.tour_transit (tour_id, direction, stop_id, note) values "
                f"({q(t['id'])}, 'to', {q(t['stopA']['id'])}, {q('Demo: ca. %d Min. Fahrt' % ride['toStartMin'] if 'toStartMin' in ride else None)});"
            )
        if "stopB" in t:
            lines.append(
                "insert into public.tour_transit (tour_id, direction, stop_id, note) values "
                f"({q(t['id'])}, 'from', {q(t['stopB']['id'])}, {q('Demo: ca. %d Min. Fahrt' % ride['fromEndMin'] if 'fromEndMin' in ride else None)});"
            )
        lines.append("")

    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"wrote {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
