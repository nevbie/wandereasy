import 'package:flutter_test/flutter_test.dart';
import 'package:wandern/core/geo/lat_lng.dart';
import 'package:wandern/features/navigation/domain/route_matcher.dart';

void main() {
  // L-förmige Route: 0,01° nach Norden (≈1112 m), dann nach Osten.
  const route = [
    LatLng(49.80, 9.80),
    LatLng(49.81, 9.80),
    LatLng(49.81, 9.8155), // ≈ 1112 m nach Osten
  ];
  final m = RouteMatcher(route);
  const mPerDegLng = 111320 * 0.6455; // cos(49.81°)

  test('Punkt auf der Route: Abstand 0, Strecke stimmt', () {
    final r = m.match(const LatLng(49.805, 9.80));
    expect(r.distanceToRouteM, closeTo(0, 0.5));
    expect(r.alongM, closeTo(556, 2));
    expect(r.segmentIndex, 0);
  });

  test('Punkt-zu-Polylinie: seitlicher Abstand', () {
    // 50 m östlich des ersten Abschnitts
    final r = m.match(const LatLng(49.805, 9.80 + 50 / mPerDegLng));
    expect(r.distanceToRouteM, closeTo(50, 1));
  });

  test('vor dem Start: Abstand zum Endpunkt des Abschnitts', () {
    final r = m.match(const LatLng(49.7991, 9.80)); // ≈100 m südlich
    expect(r.distanceToRouteM, closeTo(100, 2));
    expect(r.alongM, 0);
  });

  test('Ecke: nächster Abschnitt wird erkannt', () {
    final r = m.match(const LatLng(49.8102, 9.81)); // nördlich Abschnitt 2
    expect(r.segmentIndex, 1);
    expect(r.distanceToRouteM, closeTo(22, 1.5));
  });

  group('Rundweg (Start = Ziel)', () {
    const loop = [
      LatLng(49.80, 9.80),
      LatLng(49.81, 9.80),
      LatLng(49.81, 9.81),
      LatLng(49.80, 9.81),
      LatLng(49.80, 9.80),
    ];
    final lm = RouteMatcher(loop);

    test('am Start ohne Vorwissen: Anfang der Route', () {
      expect(lm.match(loop.first).alongM, lessThan(1));
    });

    test('am Ende mit Vorwissen: Ende der Route', () {
      final r = lm.match(loop.last, nearAlongM: lm.totalM - 100);
      expect(r.alongM, closeTo(lm.totalM, 1));
    });
  });

  test('Abkürzung: weit entfernte Stelle wird übernommen', () {
    // Zuletzt bei 100 m, jetzt am Ende der Route.
    final r = m.match(route.last, nearAlongM: 100, windowAheadM: 300);
    expect(r.alongM, closeTo(m.totalM, 1));
  });

  test('gegangener und verbleibender Teil', () {
    final r = m.match(const LatLng(49.81, 9.805));
    expect(m.walkedPath(r), hasLength(3));
    expect(m.remainingPath(r).last, route.last);
  });
}
