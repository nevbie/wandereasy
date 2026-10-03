import 'dart:math' as math;

import 'lat_lng.dart';

/// Kumulierte Strecke in Metern bis zu jedem Punkt der Route.
List<double> cumulativeDistances(List<LatLng> route) {
  final result = <double>[];
  var sum = 0.0;
  for (var i = 0; i < route.length; i++) {
    if (i > 0) sum += distanceM(route[i - 1], route[i]);
    result.add(sum);
  }
  return result;
}

/// Punkt auf der Route nach [meters] ab Start (linear interpoliert).
/// Werte außerhalb der Route werden auf Start bzw. Ziel begrenzt.
LatLng positionAtDistance(List<LatLng> route, double meters) {
  if (route.isEmpty) throw ArgumentError('Leere Route');
  final cum = cumulativeDistances(route);
  if (meters <= 0) return route.first;
  if (meters >= cum.last) return route.last;
  for (var i = 1; i < route.length; i++) {
    if (cum[i] >= meters) {
      final seg = cum[i] - cum[i - 1];
      final t = seg == 0 ? 0.0 : (meters - cum[i - 1]) / seg;
      final a = route[i - 1];
      final b = route[i];
      return LatLng(a.lat + (b.lat - a.lat) * t, a.lng + (b.lng - a.lng) * t);
    }
  }
  return route.last;
}

/// Umgebendes Rechteck einer Punktmenge.
class GeoBounds {
  const GeoBounds(this.south, this.west, this.north, this.east);

  factory GeoBounds.of(Iterable<LatLng> points) {
    var s = 90.0, w = 180.0, n = -90.0, e = -180.0;
    for (final p in points) {
      s = math.min(s, p.lat);
      n = math.max(n, p.lat);
      w = math.min(w, p.lng);
      e = math.max(e, p.lng);
    }
    return GeoBounds(s, w, n, e);
  }

  final double south;
  final double west;
  final double north;
  final double east;
}
