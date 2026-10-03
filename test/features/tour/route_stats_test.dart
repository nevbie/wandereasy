import 'package:flutter_test/flutter_test.dart';
import 'package:wandern/core/geo/lat_lng.dart';
import 'package:wandern/features/tour/domain/gpx.dart';
import 'package:wandern/features/tour/domain/route_stats.dart';

String gpx(List<(double, double, double?)> pts, {String tag = 'trkpt'}) {
  final body = pts
      .map(
        (p) =>
            '<$tag lat="${p.$1}" lon="${p.$2}">'
            '${p.$3 == null ? '' : '<ele>${p.$3}</ele>'}</$tag>',
      )
      .join();
  final wrap = tag == 'trkpt'
      ? '<trk><trkseg>$body</trkseg></trk>'
      : '<rte>$body</rte>';
  return '<?xml version="1.0"?><gpx version="1.1" '
      'xmlns="http://www.topografix.com/GPX/1/1">$wrap</gpx>';
}

void main() {
  group('GPX-Parser', () {
    test('liest Trackpunkte mit Höhe', () {
      final points = parseGpx(gpx([(49.8, 9.8, 180), (49.81, 9.8, 200.5)]));
      expect(points, hasLength(2));
      expect(points[0].position, const LatLng(49.8, 9.8));
      expect(points[1].elevationM, 200.5);
    });

    test('liest Routenpunkte, wenn kein Track vorhanden', () {
      final points = parseGpx(
        gpx([(49.8, 9.8, null), (49.81, 9.8, null)], tag: 'rtept'),
      );
      expect(points, hasLength(2));
      expect(points[0].elevationM, isNull);
    });

    test('Fehler bei kaputter Datei oder ohne Route', () {
      expect(() => parseGpx('<gpx'), throwsA(isA<GpxFormatException>()));
      expect(
        () => parseGpx(gpx([(49.8, 9.8, 1)])),
        throwsA(isA<GpxFormatException>()),
      );
    });
  });

  group('Streckenwerte', () {
    test('Länge per Haversine (0,01° Breite ≈ 1112 m)', () {
      final d = distanceM(const LatLng(49.8, 9.8), const LatLng(49.81, 9.8));
      expect(d, closeTo(1112, 2));
    });

    test('Höhenmeter mit Schwelle gegen Rauschen', () {
      final pts = [
        for (final (i, e) in <double>[
          100,
          101,
          100,
          102,
          110,
          120,
          119,
          120,
          100,
        ].indexed)
          TrackPoint(LatLng(49.8 + i * 0.001, 9.8), e),
      ];
      final s = computeRouteStats(pts);
      expect(s.ascentM, 20);
      expect(s.descentM, 20);
      expect(s.profile, hasLength(9));
      expect(s.profile.first.distanceM, 0);
      expect(s.profile.last.distanceM, closeTo(s.distanceM, 0.001));
    });
  });

  group('Gehzeit nach DIN 33466', () {
    test('flach: 4 km/h', () {
      expect(
        walkingTimeMinDin33466(distanceM: 8000, ascentM: 0, descentM: 0),
        120,
      );
    });

    test('Strecke überwiegt: Zeit Strecke + halbe Zeit Höhe', () {
      // 12 km = 3 h; 300 Hm hoch = 1 h, 300 Hm runter = 0,6 h → 1,6 h
      // 3 + 1,6 / 2 = 3,8 h = 228 Min.
      expect(
        walkingTimeMinDin33466(distanceM: 12000, ascentM: 300, descentM: 300),
        228,
      );
    });

    test('Höhe überwiegt: Zeit Höhe + halbe Zeit Strecke', () {
      // 2 km = 0,5 h; 600 Hm hoch = 2 h → 2 + 0,25 = 2,25 h = 135 Min.
      expect(
        walkingTimeMinDin33466(distanceM: 2000, ascentM: 600, descentM: 0),
        135,
      );
    });
  });
}
