import '../../../core/geo/lat_lng.dart';
import '../domain/food_place.dart';
import '../domain/route_stats.dart';
import '../domain/tour.dart';

/// Vollständige (De-)Serialisierung einer Tour für die Offline-Ablage.
abstract final class TourCodec {
  static Map<String, Object?> toJson(Tour t) => {
    'id': t.id,
    'name': t.name,
    'description': t.description,
    'tourType': t.tourType.name,
    'startPointIds': t.startPointIds,
    'difficulty': t.difficulty.name,
    'distanceM': t.distanceM,
    'ascentM': t.ascentM,
    'descentM': t.descentM,
    'durationMin': t.durationMin,
    'surfaceNotes': t.surfaceNotes,
    'warnings': t.warnings,
    // Kompakt: [lat, lng] bzw. [d_m, ele_m]
    'route': [
      for (final p in t.route) [p.lat, p.lng],
    ],
    'profile': [
      for (final p in t.profile) [p.distanceM, p.elevationM],
    ],
    'stopA': _stopToJson(t.stopA),
    'stopB': _stopToJson(t.stopB),
    'ride': {
      'toStartMin': t.ride.toStartMin,
      'fromEndMin': t.ride.fromEndMin,
      'toStartTransfers': t.ride.toStartTransfers,
      'fromEndTransfers': t.ride.fromEndTransfers,
    },
    'scenery': t.scenery.name,
    'food': [
      for (final f in t.food)
        {
          'place': _placeToJson(f.place),
          'position': f.position.name,
          'atKm': f.atKm,
          'detourMin': f.detourMin,
        },
    ],
    'pois': [
      for (final p in t.pois)
        {
          'kind': p.kind.name,
          'name': p.name,
          'note': p.note,
          'atKm': p.atKm,
          'location': _latLngToJson(p.location),
        },
    ],
    'isDemo': t.isDemo,
  };

  static Tour fromJson(Map<String, dynamic> j) => Tour(
    id: j['id'] as String,
    name: j['name'] as String,
    description: j['description'] as String,
    tourType: TourType.values.byName(j['tourType'] as String),
    startPointIds: _strings(j['startPointIds']),
    difficulty: Difficulty.values.byName(j['difficulty'] as String),
    distanceM: _d(j['distanceM'])!,
    ascentM: _d(j['ascentM'])!,
    descentM: _d(j['descentM'])!,
    durationMin: j['durationMin'] as int,
    surfaceNotes: j['surfaceNotes'] as String?,
    warnings: _strings(j['warnings']),
    route: [
      for (final p in j['route'] as List<dynamic>)
        LatLng(_d((p as List<dynamic>)[0])!, _d(p[1])!),
    ],
    profile: [
      for (final p in j['profile'] as List<dynamic>)
        ElevationPoint(_d((p as List<dynamic>)[0])!, _d(p[1])!),
    ],
    stopA: _stopFromJson(j['stopA']),
    stopB: _stopFromJson(j['stopB']),
    ride: _rideFromJson(j['ride'] as Map<String, dynamic>),
    scenery: Scenery.values.byName(j['scenery'] as String? ?? 'normal'),
    food: [
      for (final raw in j['food'] as List<dynamic>)
        _foodFromJson(raw as Map<String, dynamic>),
    ],
    pois: [
      for (final raw in j['pois'] as List<dynamic>)
        _poiFromJson(raw as Map<String, dynamic>),
    ],
    isDemo: j['isDemo'] as bool,
  );

  static RideEstimate _rideFromJson(Map<String, dynamic> r) => RideEstimate(
    toStartMin: r['toStartMin'] as int?,
    fromEndMin: r['fromEndMin'] as int?,
    toStartTransfers: r['toStartTransfers'] as int?,
    fromEndTransfers: r['fromEndTransfers'] as int?,
  );

  static double? _d(Object? v) => (v as num?)?.toDouble();

  static List<String> _strings(Object? v) => [
    for (final s in v as List<dynamic>) s as String,
  ];

  static List<double>? _latLngToJson(LatLng? p) =>
      p == null ? null : [p.lat, p.lng];

  static LatLng? _latLngFromJson(Object? v) {
    if (v == null) return null;
    final l = v as List<dynamic>;
    return LatLng(_d(l[0])!, _d(l[1])!);
  }

  static Map<String, String>? _stopToJson(StopRef? s) =>
      s == null ? null : {'id': s.id, 'name': s.name};

  static StopRef? _stopFromJson(Object? v) {
    if (v == null) return null;
    final m = v as Map<String, dynamic>;
    return StopRef(id: m['id'] as String, name: m['name'] as String);
  }

  static Map<String, Object?> _placeToJson(FoodPlace p) => {
    'id': p.id,
    'name': p.name,
    'kind': p.kind.name,
    'phone': p.phone,
    'location': _latLngToJson(p.location),
    'openingHours': p.openingHours,
    'restDays': p.restDays,
    'seasonFrom': _monthDay(p.seasonFrom),
    'seasonTo': _monthDay(p.seasonTo),
    'note': p.note,
    'isDemo': p.isDemo,
  };

  static String? _monthDay(MonthDay? m) => m == null
      ? null
      : '${m.month.toString().padLeft(2, '0')}-'
            '${m.day.toString().padLeft(2, '0')}';

  static TourFood _foodFromJson(Map<String, dynamic> f) {
    final p = f['place'] as Map<String, dynamic>;
    return TourFood(
      place: FoodPlace(
        id: p['id'] as String,
        name: p['name'] as String,
        kind: FoodKind.values.byName(p['kind'] as String),
        phone: p['phone'] as String?,
        location: _latLngFromJson(p['location']),
        openingHours: p['openingHours'] as String?,
        restDays: [for (final d in p['restDays'] as List<dynamic>) d as int],
        seasonFrom: p['seasonFrom'] == null
            ? null
            : MonthDay.parse(p['seasonFrom'] as String),
        seasonTo: p['seasonTo'] == null
            ? null
            : MonthDay.parse(p['seasonTo'] as String),
        note: p['note'] as String?,
        isDemo: p['isDemo'] as bool,
      ),
      position: FoodPosition.values.byName(f['position'] as String),
      atKm: _d(f['atKm']),
      detourMin: f['detourMin'] as int,
    );
  }

  static Poi _poiFromJson(Map<String, dynamic> p) => Poi(
    kind: PoiKind.values.byName(p['kind'] as String),
    name: p['name'] as String,
    note: p['note'] as String?,
    atKm: _d(p['atKm']),
    location: _latLngFromJson(p['location']),
  );
}
