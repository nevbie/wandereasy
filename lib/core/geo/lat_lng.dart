import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Geografischer Punkt (WGS84). Bewusst eigene Klasse, damit die Domäne
/// nicht vom Kartenpaket abhängt.
@immutable
class LatLng {
  const LatLng(this.lat, this.lng);

  final double lat;
  final double lng;

  @override
  bool operator ==(Object other) =>
      other is LatLng && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);

  @override
  String toString() => 'LatLng($lat, $lng)';
}

const double _earthRadiusM = 6371000;

double _rad(double deg) => deg * math.pi / 180;

/// Entfernung zweier Punkte in Metern (Haversine).
double distanceM(LatLng a, LatLng b) {
  final dLat = _rad(b.lat - a.lat);
  final dLng = _rad(b.lng - a.lng);
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(_rad(a.lat)) *
          math.cos(_rad(b.lat)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * _earthRadiusM * math.asin(math.min(1, math.sqrt(h)));
}
