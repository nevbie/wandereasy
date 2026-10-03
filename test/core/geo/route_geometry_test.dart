import 'package:flutter_test/flutter_test.dart';
import 'package:wandern/core/geo/lat_lng.dart';
import 'package:wandern/core/geo/route_geometry.dart';

void main() {
  // Zwei Abschnitte nach Norden, je 0,01° ≈ 1112 m.
  const route = [LatLng(49.80, 9.8), LatLng(49.81, 9.8), LatLng(49.82, 9.8)];

  test('kumulierte Strecke', () {
    final cum = cumulativeDistances(route);
    expect(cum[0], 0);
    expect(cum[1], closeTo(1112, 2));
    expect(cum[2], closeTo(2224, 4));
  });

  test('Position bei Strecke, interpoliert und begrenzt', () {
    expect(positionAtDistance(route, -5), route.first);
    expect(positionAtDistance(route, 99999), route.last);
    expect(positionAtDistance(route, 556).lat, closeTo(49.805, 0.0001));
    expect(positionAtDistance(route, 1112 + 556).lat, closeTo(49.815, 0.0002));
  });

  test('Grenzen', () {
    final b = GeoBounds.of(const [LatLng(1, 5), LatLng(-2, 7), LatLng(3, 6)]);
    expect([b.south, b.west, b.north, b.east], [-2, 5, 3, 7]);
  });
}
