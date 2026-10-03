import 'dart:math' as math;

import '../../../core/geo/lat_lng.dart';
import '../../../core/geo/route_geometry.dart';

/// Ergebnis des Abgleichs einer Position mit der Route.
class RouteMatch {
  const RouteMatch({
    required this.distanceToRouteM,
    required this.alongM,
    required this.segmentIndex,
    required this.pointOnRoute,
  });

  /// Kürzeste Entfernung zur Route (Punkt-zu-Polylinie).
  final double distanceToRouteM;

  /// Strecke vom Start bis zum nächstgelegenen Punkt auf der Route.
  final double alongM;

  /// Index des Abschnitts `route[i] → route[i + 1]`.
  final int segmentIndex;
  final LatLng pointOnRoute;
}

const double _earthRadiusM = 6371000;

/// Abgleich von Positionen mit einer Route.
///
/// Für kurze Entfernungen genügt eine lokale ebene Projektion um die
/// Position (Fehler im Zentimeterbereich).
class RouteMatcher {
  RouteMatcher(this.route)
    : assert(route.length >= 2),
      _cum = cumulativeDistances(route);

  final List<LatLng> route;
  final List<double> _cum;

  double get totalM => _cum.last;

  /// Strecke vom Start bis zum Routenpunkt [index].
  double alongAt(int index) => _cum[index];

  /// Nächster Punkt der Route zu [p].
  ///
  /// Mit [nearAlongM] wird bevorzugt in der Nähe der zuletzt bekannten
  /// Position gesucht ([windowBackM] zurück, [windowAheadM] voraus). So
  /// springt die Anzeige bei Rundwegen und Wegen, die sich kreuzen oder
  /// zweimal genutzt werden, nicht auf den falschen Abschnitt. Liegt die
  /// Position im Fenster weit von der Route, an anderer Stelle aber nahe
  /// ([rejoinM]), gilt die andere Stelle (z. B. nach einer Abkürzung).
  RouteMatch match(
    LatLng p, {
    double? nearAlongM,
    double windowBackM = 150,
    double windowAheadM = 1000,
    double rejoinM = 40,
  }) {
    final global = _best(p, 0, route.length - 2);
    if (nearAlongM == null) return global;

    final from = nearAlongM - windowBackM;
    final to = nearAlongM + windowAheadM;
    var first = 0;
    while (first < route.length - 2 && _cum[first + 1] < from) {
      first++;
    }
    var last = first;
    while (last < route.length - 2 && _cum[last + 1] <= to) {
      last++;
    }
    final windowed = _best(p, first, last);
    if (windowed.distanceToRouteM > rejoinM &&
        global.distanceToRouteM <= rejoinM) {
      return global;
    }
    return windowed;
  }

  RouteMatch _best(LatLng p, int firstSegment, int lastSegment) {
    RouteMatch? best;
    final cosLat = math.cos(p.lat * math.pi / 180);
    double x(LatLng q) =>
        (q.lng - p.lng) * cosLat * _earthRadiusM * math.pi / 180;
    double y(LatLng q) => (q.lat - p.lat) * _earthRadiusM * math.pi / 180;

    for (var i = firstSegment; i <= lastSegment; i++) {
      final a = route[i];
      final b = route[i + 1];
      final ax = x(a), ay = y(a), bx = x(b), by = y(b);
      final dx = bx - ax, dy = by - ay;
      final len2 = dx * dx + dy * dy;
      final t = len2 == 0
          ? 0.0
          : (-(ax * dx + ay * dy) / len2).clamp(0.0, 1.0).toDouble();
      final cx = ax + t * dx, cy = ay + t * dy;
      final dist = math.sqrt(cx * cx + cy * cy);
      // Bei Gleichstand (Rundweg: Start = Ziel) gewinnt der frühere
      // Abschnitt; 1 m Toleranz gegen Rundungsrauschen.
      if (best == null || dist < best.distanceToRouteM - 1) {
        best = RouteMatch(
          distanceToRouteM: dist,
          alongM: _cum[i] + t * (_cum[i + 1] - _cum[i]),
          segmentIndex: i,
          pointOnRoute: LatLng(
            a.lat + (b.lat - a.lat) * t,
            a.lng + (b.lng - a.lng) * t,
          ),
        );
      }
    }
    return best!;
  }

  /// Bereits gegangener Teil der Route bis [match] (für die graue Linie).
  List<LatLng> walkedPath(RouteMatch match) => [
    ...route.take(match.segmentIndex + 1),
    match.pointOnRoute,
  ];

  /// Noch zu gehender Teil der Route ab [match].
  List<LatLng> remainingPath(RouteMatch match) => [
    match.pointOnRoute,
    ...route.skip(match.segmentIndex + 1),
  ];
}
