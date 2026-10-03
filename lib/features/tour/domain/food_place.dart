import 'package:flutter/foundation.dart';

import '../../../core/geo/lat_lng.dart';

enum FoodKind { gasthaus, haeckerwirtschaft, cafe, huette, biergarten, other }

/// Lage der Einkehr bezogen auf die Tour (`tour_food.position`).
enum FoodPosition { onRoute, atEnd, atStart }

/// Tag im Jahr ohne Jahreszahl, für jährlich wiederkehrende Saisons.
@immutable
class MonthDay implements Comparable<MonthDay> {
  const MonthDay(this.month, this.day);

  factory MonthDay.of(DateTime date) => MonthDay(date.month, date.day);

  /// Liest `MM-DD`.
  factory MonthDay.parse(String s) {
    final parts = s.split('-');
    return MonthDay(int.parse(parts[0]), int.parse(parts[1]));
  }

  final int month;
  final int day;

  @override
  int compareTo(MonthDay other) =>
      month != other.month ? month - other.month : day - other.day;

  bool operator <=(MonthDay other) => compareTo(other) <= 0;

  @override
  bool operator ==(Object other) =>
      other is MonthDay && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(month, day);
}

@immutable
class FoodPlace {
  const FoodPlace({
    required this.id,
    required this.name,
    required this.kind,
    this.phone,
    this.location,
    this.openingHours,
    this.restDays = const [],
    this.seasonFrom,
    this.seasonTo,
    this.note,
    this.isDemo = false,
  });

  final String id;
  final String name;
  final FoodKind kind;
  final String? phone;
  final LatLng? location;

  /// Öffnungszeiten in OSM-Syntax, z. B. `Mo-Fr 11:00-22:00; Tu off`.
  final String? openingHours;

  /// Ruhetage, 1 = Montag … 7 = Sonntag.
  final List<int> restDays;

  /// Saison (jährlich wiederkehrend), z. B. bei Häckerwirtschaften.
  final MonthDay? seasonFrom;
  final MonthDay? seasonTo;
  final String? note;
  final bool isDemo;

  bool get isSeasonal => seasonFrom != null && seasonTo != null;
}

/// Verknüpfung Tour ↔ Einkehr (`tour_food`).
@immutable
class TourFood {
  const TourFood({
    required this.place,
    required this.position,
    this.atKm,
    this.detourMin = 0,
  });

  final FoodPlace place;
  final FoodPosition position;
  final double? atKm;
  final int detourMin;
}
