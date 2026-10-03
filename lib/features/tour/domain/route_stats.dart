import 'dart:math' as math;

import '../../../core/geo/lat_lng.dart';
import 'gpx.dart';

/// Punkt des Höhenprofils: Strecke ab Start und Höhe.
class ElevationPoint {
  const ElevationPoint(this.distanceM, this.elevationM);

  final double distanceM;
  final double elevationM;
}

class RouteStats {
  const RouteStats({
    required this.distanceM,
    required this.ascentM,
    required this.descentM,
    required this.profile,
  });

  final double distanceM;
  final double ascentM;
  final double descentM;
  final List<ElevationPoint> profile;
}

/// Berechnet Länge, Höhenmeter und Profil einer Route.
///
/// Höhenmeter mit Schwelle [thresholdM] (Hysterese), damit Messrauschen
/// aus GPS-Höhen nicht zu viele Höhenmeter ergibt.
RouteStats computeRouteStats(List<TrackPoint> points, {double thresholdM = 3}) {
  var distance = 0.0;
  var ascent = 0.0;
  var descent = 0.0;
  final profile = <ElevationPoint>[];
  double? reference;

  for (var i = 0; i < points.length; i++) {
    if (i > 0) {
      distance += distanceM(points[i - 1].position, points[i].position);
    }
    final ele = points[i].elevationM;
    if (ele == null) continue;
    profile.add(ElevationPoint(distance, ele));

    if (reference == null) {
      reference = ele;
    } else if (ele - reference >= thresholdM) {
      ascent += ele - reference;
      reference = ele;
    } else if (reference - ele >= thresholdM) {
      descent += reference - ele;
      reference = ele;
    }
  }

  return RouteStats(
    distanceM: distance,
    ascentM: ascent,
    descentM: descent,
    profile: profile,
  );
}

/// Gehzeit in Minuten nach DIN 33466 (Wanderzeit-Formel).
///
/// Horizontal 4 km/h, bergauf 300 Hm/h, bergab 500 Hm/h. Die Zeit für die
/// Strecke und die Zeit für die Höhenmeter werden berechnet; die größere
/// plus die Hälfte der kleineren ergibt die Gehzeit (ohne Pausen).
int walkingTimeMinDin33466({
  required double distanceM,
  required double ascentM,
  required double descentM,
}) {
  final horizontalH = distanceM / 1000 / 4;
  final verticalH = ascentM / 300 + descentM / 500;
  final hours =
      math.max(horizontalH, verticalH) + math.min(horizontalH, verticalH) / 2;
  return (hours * 60).round();
}
