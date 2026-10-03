import 'package:flutter/foundation.dart';

import '../../../core/geo/lat_lng.dart';

/// IDs der beiden Startpunkte (SPEC 1, genau diese zwei).
abstract final class StartPointIds {
  static const String naturfreundehaus = 'nfh_vhh';
  static const String bahnhof = 'bf_vhh';
  static const List<String> all = [naturfreundehaus, bahnhof];
}

@immutable
class StartPoint {
  const StartPoint({
    required this.id,
    required this.location,
    required this.walkMinToStation,
  });

  final String id;

  /// `null`, solange die Koordinaten nicht bestätigt sind (SPEC 11:
  /// nicht erfinden, per Geocoding ermitteln oder vom Verein bestätigen).
  final LatLng? location;

  /// Fußweg zum Bahnhof Veitshöchheim in Minuten (0 = liegt dort).
  final int walkMinToStation;

  bool get isStation => walkMinToStation == 0;
}

// ANNAHME: Fußweg Naturfreundehaus → Bahnhof als Demo-Schätzung (15 Min.),
// bis er in M4 per Fußwege-Routing berechnet wird (siehe DECISIONS.md).
const List<StartPoint> startPoints = [
  StartPoint(
    id: StartPointIds.naturfreundehaus,
    location: null,
    walkMinToStation: 15,
  ),
  StartPoint(id: StartPointIds.bahnhof, location: null, walkMinToStation: 0),
];

StartPoint startPointById(String id) =>
    startPoints.firstWhere((p) => p.id == id);
