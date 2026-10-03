import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandern/features/tour/data/demo_tour_repository.dart';
import 'package:wandern/features/tour/domain/tour.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Demo-Daten: je Tourenart eine Tour mit Einkehr (SPEC 11)', () async {
    final tours = await DemoTourRepository(rootBundle).allTours();

    expect(tours.map((t) => t.tourType).toSet(), TourType.values.toSet());
    expect(tours, hasLength(3));
    for (final t in tours) {
      expect(t.isDemo, isTrue, reason: t.id);
      expect(t.hasFood, isTrue, reason: t.id);
      expect(t.route.length, greaterThan(10), reason: t.id);
      expect(t.durationMin, greaterThan(30), reason: t.id);
      expect(t.food.every((f) => f.place.isDemo), isTrue, reason: t.id);
    }

    final ride = tours.firstWhere((t) => t.tourType == TourType.rideBothWays);
    expect(ride.stopA, isNotNull);
    expect(ride.stopB, isNotNull);
    expect(ride.stopA!.id, isNot(ride.stopB!.id));

    final walk = tours.firstWhere(
      (t) => t.tourType == TourType.walkOutRideBack,
    );
    expect(walk.stopB, isNotNull);
  });

  test('Platzhalter Höhfeldplatte ist nicht veröffentlicht', () async {
    final tours = await DemoTourRepository(rootBundle).allTours();
    expect(tours.where((t) => t.id.contains('hoehfeld')), isEmpty);
  });
}
