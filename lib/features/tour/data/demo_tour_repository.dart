import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/food_place.dart';
import '../domain/gpx.dart';
import '../domain/route_stats.dart';
import '../domain/tour.dart';
import '../domain/tour_repository.dart';

/// Lädt die Demo-Touren aus `assets/demo/` (SPEC 11).
class DemoTourRepository implements TourRepository {
  DemoTourRepository(this._bundle);

  static const String indexAsset = 'assets/demo/tours.json';

  final AssetBundle _bundle;
  Future<List<Tour>>? _cache;

  @override
  Future<List<Tour>> allTours() => _cache ??= _load();

  Future<List<Tour>> _load() async {
    final json = jsonDecode(
      await _bundle.loadString(indexAsset),
    ) as Map<String, dynamic>;
    final gpx = <String, String>{};
    for (final t in json['tours'] as List<dynamic>) {
      final path = (t as Map<String, dynamic>)['gpx'] as String?;
      if (path != null) gpx[path] = await _bundle.loadString(path);
    }
    return parseDemoTours(json, gpx);
  }
}

/// Wandelt die Demo-JSON in Touren um. [gpxByPath] enthält den Inhalt der
/// referenzierten GPX-Dateien. Unveröffentlichte Touren werden übersprungen.
List<Tour> parseDemoTours(
  Map<String, dynamic> json,
  Map<String, String> gpxByPath,
) {
  final places = {
    for (final p in json['foodPlaces'] as List<dynamic>)
      (p as Map<String, dynamic>)['id'] as String: _foodPlace(p),
  };

  final tours = <Tour>[];
  for (final raw in json['tours'] as List<dynamic>) {
    final t = raw as Map<String, dynamic>;
    if (t['published'] == false) continue;

    final points = parseGpx(gpxByPath[t['gpx'] as String]!);
    final stats = computeRouteStats(points);

    tours.add(
      Tour(
        id: t['id'] as String,
        name: t['name'] as String,
        description: t['description'] as String,
        tourType: TourType.values.byName(t['tourType'] as String),
        startPointIds: _strings(t['startPointIds']),
        difficulty: Difficulty.values.byName(t['difficulty'] as String),
        distanceM: stats.distanceM,
        ascentM: stats.ascentM,
        descentM: stats.descentM,
        durationMin:
            (t['durationMin'] as int?) ??
            walkingTimeMinDin33466(
              distanceM: stats.distanceM,
              ascentM: stats.ascentM,
              descentM: stats.descentM,
            ),
        surfaceNotes: t['surfaceNotes'] as String?,
        warnings: _strings(t['warnings']),
        route: [for (final p in points) p.position],
        profile: stats.profile,
        stopA: _stop(t['stopA']),
        stopB: _stop(t['stopB']),
        ride: _ride(t['ride']),
        food: [
          for (final f in (t['food'] as List<dynamic>? ?? const []))
            _tourFood(f as Map<String, dynamic>, places),
        ],
        pois: [
          for (final p in (t['pois'] as List<dynamic>? ?? const []))
            _poi(p as Map<String, dynamic>),
        ],
        isDemo: t['isDemo'] as bool? ?? true,
      ),
    );
  }
  return tours;
}

List<String> _strings(Object? v) => [
  for (final s in (v as List<dynamic>? ?? const [])) s as String,
];

double? _double(Object? v) => (v as num?)?.toDouble();

FoodPlace _foodPlace(Map<String, dynamic> p) => FoodPlace(
  id: p['id'] as String,
  name: p['name'] as String,
  kind: FoodKind.values.byName(p['kind'] as String),
  phone: p['phone'] as String?,
  openingHours: p['openingHours'] as String?,
  restDays: [for (final d in (p['restDays'] as List<dynamic>? ?? [])) d as int],
  seasonFrom: p['seasonFrom'] == null
      ? null
      : MonthDay.parse(p['seasonFrom'] as String),
  seasonTo: p['seasonTo'] == null
      ? null
      : MonthDay.parse(p['seasonTo'] as String),
  note: p['note'] as String?,
  isDemo: p['isDemo'] as bool? ?? true,
);

StopRef? _stop(Object? v) {
  if (v == null) return null;
  final m = v as Map<String, dynamic>;
  return StopRef(id: m['id'] as String, name: m['name'] as String);
}

RideEstimate _ride(Object? v) {
  if (v == null) return const RideEstimate();
  final m = v as Map<String, dynamic>;
  return RideEstimate(
    toStartMin: m['toStartMin'] as int?,
    fromEndMin: m['fromEndMin'] as int?,
  );
}

TourFood _tourFood(Map<String, dynamic> f, Map<String, FoodPlace> places) =>
    TourFood(
      place: places[f['placeId'] as String]!,
      position: FoodPosition.values.byName(f['position'] as String),
      atKm: _double(f['atKm']),
      detourMin: f['detourMin'] as int? ?? 0,
    );

Poi _poi(Map<String, dynamic> p) => Poi(
  kind: PoiKind.values.byName(p['kind'] as String),
  name: p['name'] as String,
  note: p['note'] as String?,
  atKm: _double(p['atKm']),
);
