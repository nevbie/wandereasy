import 'dart:math' as math;

import '../../tour/domain/food_place.dart';
import '../../tour/domain/opening.dart';
import '../../tour/domain/start_point.dart';
import '../../tour/domain/tour.dart';
import '../../tour/domain/tour_places.dart';
import 'search_criteria.dart';

/// Regeln für Vorschläge. Werte als Konstanten, damit der Verein sie
/// leicht anpassen kann.
abstract final class SuggestionRules {
  /// Längste Strecke in km.
  static const double maxKm = 20;

  /// Höchste „Leistungskilometer“: km + Höhenmeter bergauf / 100.
  /// Ergibt z. B. 20 km im Flachen, 18 km mit 200 Hm, 15 km mit 500 Hm.
  static const double maxEffortKm = 20;

  // Gewichte der Rangfolge (höher = weiter oben).
  static const int pointsPerSceneryLevel = 4;
  static const int pointsFoodAtEnd = 3;
  static const int pointsFoodOnTheWay = 1;
  static const int pointsDirectRide = 2;
  static const int pointsPerExtraTransfer = -2;
}

/// Leistungskilometer: Strecke plus Höhenmeter bergauf / 100.
double effortKm(Tour tour) => tour.distanceM / 1000 + tour.ascentM / 100;

/// Ist die Tour für Vorschläge nicht zu lang (SPEC-Änderung: bis 15/20 km
/// je nach Höhenprofil)?
bool withinLengthLimit(Tour tour) =>
    tour.distanceM / 1000 <= SuggestionRules.maxKm &&
    effortKm(tour) <= SuggestionRules.maxEffortKm;

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

/// Größte Zahl an Umstiegen einer Fahrt; `0` ohne Fahrt, `null` unbekannt.
int? maxTransfers(Tour tour) {
  final r = tour.ride;
  return switch (tour.tourType) {
    TourType.loop => 0,
    TourType.walkOutRideBack => r.fromEndTransfers,
    TourType.rideBothWays =>
      r.toStartTransfers == null || r.fromEndTransfers == null
          ? null
          : math.max(r.toStartTransfers!, r.fromEndTransfers!),
  };
}

/// Hat die Tour eine Einkehr, die am Tag [date] nicht sicher geschlossen
/// ist? Ohne Datum genügt irgendeine Einkehr.
// ANNAHME: Unbekannte Öffnungszeiten zählen als „vielleicht geöffnet“ und
// werden nicht ausgefiltert; die Anzeige sagt dann „bitte vorher prüfen“.
bool hasFoodOn(Tour tour, DateTime? date) {
  if (date == null) return tour.hasFood;
  return tour.food.any((f) => _mayBeOpen(f, date));
}

bool _mayBeOpen(TourFood f, DateTime date) {
  final status = openingStatusOn(f.place, date);
  return status == OpeningStatus.open || status == OpeningStatus.unknown;
}

/// Prüft eine einzelne Tour gegen alle Antworten.
bool matchesCriteria(Tour tour, SearchCriteria c, {bool limitLength = true}) {
  if (!tour.fitsStartPoint(c.startPointId)) return false;
  if (c.tourType != null && tour.tourType != c.tourType) return false;
  if (!c.duration.matches(tour.durationMin)) return false;
  if (!c.effort.matches(tour.difficulty)) return false;
  if (limitLength && !withinLengthLimit(tour)) return false;
  if (c.requireFood && !hasFoodOn(tour, c.date)) return false;

  final maxRide = c.ride.maxMin;
  if (maxRide != null && tour.tourType != TourType.loop) {
    final travel = oneWayTravelMin(tour, startPointById(c.startPointId));
    if (travel == null || travel > maxRide) return false;
  }
  return true;
}

/// Punkte für die Rangfolge der Vorschläge: schöne Landschaft zuerst,
/// Einkehr lieber am Schluss, Fahrt lieber ohne Umsteigen.
int suggestionScore(Tour tour, {DateTime? date}) {
  var score = tour.scenery.index * SuggestionRules.pointsPerSceneryLevel;

  final usable = [
    for (final f in tour.food)
      if (date == null || _mayBeOpen(f, date)) f,
  ];
  if (usable.any((f) => isLateFood(tour, f))) {
    score += SuggestionRules.pointsFoodAtEnd;
  } else if (usable.isNotEmpty) {
    score += SuggestionRules.pointsFoodOnTheWay;
  }

  if (tour.tourType != TourType.loop) {
    final transfers = maxTransfers(tour);
    if (transfers == 0) {
      score += SuggestionRules.pointsDirectRide;
    } else if (transfers != null && transfers > 1) {
      score += (transfers - 1) * SuggestionRules.pointsPerExtraTransfer;
    }
  }
  return score;
}

/// Filterlogik der Fragen-Suche (SPEC 5.2) als reine Funktion.
///
/// Rangfolge: Punkte aus [suggestionScore] (höchste zuerst), dann kürzere
/// Gehzeit, dann Name. [limitLength]: Längenobergrenze anwenden (für
/// „Alle Touren zeigen“ abschaltbar).
List<Tour> filterTours(
  Iterable<Tour> tours,
  SearchCriteria criteria, {
  bool limitLength = true,
}) {
  final scores = <Tour, int>{};
  int score(Tour t) => scores[t] ??= suggestionScore(t, date: criteria.date);
  return tours
      .where((t) => matchesCriteria(t, criteria, limitLength: limitLength))
      .toList()
    ..sort((a, b) {
      final byScore = score(b).compareTo(score(a));
      if (byScore != 0) return byScore;
      final byDuration = a.durationMin.compareTo(b.durationMin);
      return byDuration != 0 ? byDuration : a.name.compareTo(b.name);
    });
}
