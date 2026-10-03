import 'dart:math' as math;

import '../../../core/geo/lat_lng.dart';
import '../../../core/geo/route_geometry.dart';
import 'navigation_engine.dart';

/// Ein Abstecher von der Route für Simulation und Tests.
class Detour {
  const Detour({
    required this.atM,
    required this.offsetM,
    required this.duration,
  });

  /// Wo auf der Route der Abstecher beginnt.
  final double atM;

  /// Wie weit seitlich man steht.
  final double offsetM;

  /// Wie lange man dort bleibt.
  final Duration duration;
}

/// Erzeugt einen GPS-Track, der die Route mit [speedMps] abläuft
/// (Standort alle [interval]). Optional mit Abstechern und
/// gleichmäßigem Rauschen [jitterM] (deterministisch über [seed]).
List<LocationFix> simulateWalk(
  List<LatLng> route, {
  required DateTime start,
  double speedMps = 1.1,
  Duration interval = const Duration(seconds: 5),
  List<Detour> detours = const [],
  double jitterM = 0,
  int seed = 1,
}) {
  final total = cumulativeDistances(route).last;
  final rnd = math.Random(seed);
  final fixes = <LocationFix>[];
  final step = speedMps * interval.inMilliseconds / 1000;
  var time = start;
  final pending = [...detours]..sort((a, b) => a.atM.compareTo(b.atM));

  LatLng jitter(LatLng p) {
    if (jitterM == 0) return p;
    return _offset(
      p,
      (rnd.nextDouble() * 2 - 1) * jitterM,
      (rnd.nextDouble() * 2 - 1) * jitterM,
    );
  }

  for (var along = 0.0; ; along = math.min(total, along + step)) {
    if (pending.isNotEmpty && along >= pending.first.atM) {
      final d = pending.removeAt(0);
      final base = positionAtDistance(route, along);
      final ahead = positionAtDistance(route, math.min(total, along + 5));
      final side = _perpendicular(base, ahead, d.offsetM);
      final end = time.add(d.duration);
      while (!time.isAfter(end)) {
        fixes.add(LocationFix(jitter(side), time, accuracyM: 8));
        time = time.add(interval);
      }
    }
    fixes.add(
      LocationFix(jitter(positionAtDistance(route, along)), time, accuracyM: 8),
    );
    time = time.add(interval);
    if (along >= total) break;
  }
  return fixes;
}

const double _mPerDegLat = 111320;

LatLng _offset(LatLng p, double eastM, double northM) => LatLng(
  p.lat + northM / _mPerDegLat,
  p.lng + eastM / (_mPerDegLat * math.cos(p.lat * math.pi / 180)),
);

/// Punkt [offsetM] Meter rechts der Laufrichtung a → b.
LatLng _perpendicular(LatLng a, LatLng b, double offsetM) {
  final cosLat = math.cos(a.lat * math.pi / 180);
  final dx = (b.lng - a.lng) * cosLat;
  final dy = b.lat - a.lat;
  final len = math.sqrt(dx * dx + dy * dy);
  if (len == 0) return _offset(a, offsetM, 0);
  // Rechts von (dx, dy) ist (dy, -dx).
  return _offset(a, dy / len * offsetM, -dx / len * offsetM);
}
