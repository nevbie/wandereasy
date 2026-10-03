import 'package:flutter/foundation.dart';

import '../../../core/geo/lat_lng.dart';
import 'food_place.dart';
import 'route_stats.dart';

/// Tourenart (SPEC 1).
enum TourType {
  /// Rundweg ab Startpunkt, ohne Bus und Bahn.
  loop,

  /// Zu Fuß los, mit Bus/Bahn zurück.
  walkOutRideBack,

  /// Mit Bus/Bahn hin, wandern von A nach B, mit Bus/Bahn zurück.
  rideBothWays;

  /// Anzahl der Fahrten mit Bus und Bahn.
  int get rides => switch (this) {
    loop => 0,
    walkOutRideBack => 1,
    rideBothWays => 2,
  };
}

enum Difficulty { easy, medium, hard }

enum PoiKind { wc, bench, viewpoint, shortcut, info }

@immutable
class Poi {
  const Poi({
    required this.kind,
    required this.name,
    this.note,
    this.atKm,
    this.location,
  });

  final PoiKind kind;
  final String name;
  final String? note;
  final double? atKm;
  final LatLng? location;
}

/// Haltestelle (vereinfacht, Details ab M4).
@immutable
class StopRef {
  const StopRef({required this.id, required this.name});

  final String id;
  final String name;
}

/// Geschätzte Fahrzeiten einer Tour, einfache Richtung, ab Bahnhof
/// Veitshöchheim (ohne Fußweg vom Startpunkt).
// ANNAHME: Bis zum Tagesablauf (M4) reichen gepflegte Schätzwerte je Tour.
@immutable
class RideEstimate {
  const RideEstimate({this.toStartMin, this.fromEndMin});

  /// Hinfahrt zu Haltestelle A (nur `rideBothWays`).
  final int? toStartMin;

  /// Rückfahrt ab Haltestelle B.
  final int? fromEndMin;
}

@immutable
class Tour {
  const Tour({
    required this.id,
    required this.name,
    required this.description,
    required this.tourType,
    required this.startPointIds,
    required this.difficulty,
    required this.distanceM,
    required this.ascentM,
    required this.descentM,
    required this.durationMin,
    this.surfaceNotes,
    this.warnings = const [],
    this.route = const [],
    this.profile = const [],
    this.stopA,
    this.stopB,
    this.ride = const RideEstimate(),
    this.food = const [],
    this.pois = const [],
    this.isDemo = false,
  });

  final String id;
  final String name;
  final String description;
  final TourType tourType;

  /// Für welche Startpunkte die Tour passt (bei `loop` und
  /// `walkOutRideBack`). Bei `rideBothWays` passt sie für alle.
  final List<String> startPointIds;
  final Difficulty difficulty;
  final double distanceM;
  final double ascentM;
  final double descentM;

  /// Reine Gehzeit ohne Pausen und Einkehr.
  final int durationMin;
  final String? surfaceNotes;
  final List<String> warnings;
  final List<LatLng> route;
  final List<ElevationPoint> profile;
  final StopRef? stopA;
  final StopRef? stopB;
  final RideEstimate ride;
  final List<TourFood> food;
  final List<Poi> pois;
  final bool isDemo;

  bool get hasFood => food.isNotEmpty;

  /// Passt die Tour zum gewählten Startpunkt?
  bool fitsStartPoint(String startPointId) =>
      tourType == TourType.rideBothWays || startPointIds.contains(startPointId);
}
