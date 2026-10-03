import 'dart:math' as math;

import '../../tour/domain/opening.dart';
import '../../tour/domain/start_point.dart';
import '../../tour/domain/tour.dart';
import 'search_criteria.dart';

/// Fahrzeit einfache Richtung ab [startPoint] in Minuten, inklusive Fußweg
/// zwischen Startpunkt und Bahnhof. Bei Hin- und Rückfahrt zählt die
/// längere Richtung. `0` bei Rundwegen, `null` wenn unbekannt.
int? oneWayTravelMin(Tour tour, StartPoint startPoint) {
  final walk = startPoint.walkMinToStation;
  final ride = tour.ride;
  switch (tour.tourType) {
    case TourType.loop:
      return 0;
    case TourType.walkOutRideBack:
      final back = ride.fromEndMin;
      return back == null ? null : back + walk;
    case TourType.rideBothWays:
      final to = ride.toStartMin;
      final back = ride.fromEndMin;
      if (to == null || back == null) return null;
      return math.max(to, back) + walk;
  }
}

/// Hat die Tour eine Einkehr, die am Tag [date] nicht sicher geschlossen
/// ist? Ohne Datum genügt irgendeine Einkehr.
// ANNAHME: Unbekannte Öffnungszeiten zählen als „vielleicht geöffnet“ und
// werden nicht ausgefiltert; die Anzeige sagt dann „bitte vorher prüfen“.
bool hasFoodOn(Tour tour, DateTime? date) {
  if (date == null) return tour.hasFood;
  return tour.food.any((f) {
    final status = openingStatusOn(f.place, date);
    return status == OpeningStatus.open || status == OpeningStatus.unknown;
  });
}

/// Prüft eine einzelne Tour gegen alle Antworten.
bool matchesCriteria(Tour tour, SearchCriteria c) {
  if (!tour.fitsStartPoint(c.startPointId)) return false;
  if (c.tourType != null && tour.tourType != c.tourType) return false;
  if (!c.duration.matches(tour.durationMin)) return false;
  if (!c.effort.matches(tour.difficulty)) return false;
  if (c.requireFood && !hasFoodOn(tour, c.date)) return false;

  final maxRide = c.ride.maxMin;
  if (c.asksRideTime && maxRide != null) {
    final travel = oneWayTravelMin(tour, startPointById(c.startPointId));
    if (travel == null || travel > maxRide) return false;
  }
  return true;
}

/// Filterlogik der Fragen-Suche (SPEC 5.2) als reine Funktion.
///
/// Sortiert nach Gehzeit (kürzeste zuerst), bei Gleichstand nach Name.
List<Tour> filterTours(Iterable<Tour> tours, SearchCriteria criteria) {
  final result = tours.where((t) => matchesCriteria(t, criteria)).toList()
    ..sort((a, b) {
      final byDuration = a.durationMin.compareTo(b.durationMin);
      return byDuration != 0 ? byDuration : a.name.compareTo(b.name);
    });
  return result;
}
