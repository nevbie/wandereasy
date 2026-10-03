import 'package:flutter_test/flutter_test.dart';
import 'package:wandern/features/search/domain/search_criteria.dart';
import 'package:wandern/features/search/domain/tour_filter.dart';
import 'package:wandern/features/tour/domain/start_point.dart';
import 'package:wandern/features/tour/domain/tour.dart';

import '../../helpers/tour_fixtures.dart';

void main() {
  const nfh = StartPointIds.naturfreundehaus;
  const bf = StartPointIds.bahnhof;

  // Je Tourenart eine Tour für beide Startpunkte und eine nur für einen.
  final tours = [
    fixtureTour(id: 'loop_both', type: TourType.loop),
    fixtureTour(id: 'loop_nfh', type: TourType.loop, startPointIds: [nfh]),
    fixtureTour(id: 'walk_both', type: TourType.walkOutRideBack),
    fixtureTour(
      id: 'walk_bf',
      type: TourType.walkOutRideBack,
      startPointIds: [bf],
    ),
    fixtureTour(id: 'ride', type: TourType.rideBothWays),
  ];

  List<String> ids(SearchCriteria c) =>
      filterTours(tours, c).map((t) => t.id).toList()..sort();

  group('Tourenart × Startpunkt (alle Kombinationen)', () {
    final expected = <(TourType?, String), List<String>>{
      (TourType.loop, nfh): ['loop_both', 'loop_nfh'],
      (TourType.loop, bf): ['loop_both'],
      (TourType.walkOutRideBack, nfh): ['walk_both'],
      (TourType.walkOutRideBack, bf): ['walk_bf', 'walk_both'],
      // Hin- und Rückfahrt passt von jedem Startpunkt.
      (TourType.rideBothWays, nfh): ['ride'],
      (TourType.rideBothWays, bf): ['ride'],
      (null, nfh): ['loop_both', 'loop_nfh', 'ride', 'walk_both'],
      (null, bf): ['loop_both', 'ride', 'walk_bf', 'walk_both'],
    };

    expected.forEach((key, want) {
      final (type, start) = key;
      test('${type?.name ?? 'egal'} ab $start', () {
        expect(ids(SearchCriteria(startPointId: start, tourType: type)), want);
      });
    });
  });

  group('Gehzeit', () {
    final byDuration = [
      fixtureTour(id: 'd120', type: TourType.loop, durationMin: 120),
      fixtureTour(id: 'd121', type: TourType.loop, durationMin: 121),
      fixtureTour(id: 'd240', type: TourType.loop, durationMin: 240),
      fixtureTour(id: 'd241', type: TourType.loop, durationMin: 241),
    ];
    List<String> run(DurationChoice d) => filterTours(
      byDuration,
      SearchCriteria(startPointId: bf, duration: d),
    ).map((t) => t.id).toList();

    test('Grenzen 2 und 4 Stunden', () {
      expect(run(DurationChoice.upTo2h), ['d120']);
      expect(run(DurationChoice.from2To4h), ['d121', 'd240']);
      expect(run(DurationChoice.longer), ['d241']);
      expect(run(DurationChoice.any), hasLength(4));
    });
  });

  group('Anstrengung', () {
    final byLevel = [
      for (final d in Difficulty.values)
        fixtureTour(id: d.name, type: TourType.loop, difficulty: d),
    ];
    List<String> run(EffortChoice e) => filterTours(
      byLevel,
      SearchCriteria(startPointId: bf, effort: e),
    ).map((t) => t.id).toList()..sort();

    test('leicht / mittel (höchstens mittel) / egal', () {
      expect(run(EffortChoice.easy), ['easy']);
      expect(run(EffortChoice.medium), ['easy', 'medium']);
      expect(run(EffortChoice.any), ['easy', 'hard', 'medium']);
    });
  });

  group('Einkehr', () {
    final withFood = [
      fixtureTour(id: 'none', type: TourType.loop),
      fixtureTour(
        id: 'always',
        type: TourType.loop,
        food: [foodAt(openEveryDay)],
      ),
      fixtureTour(
        id: 'notMo',
        type: TourType.loop,
        food: [foodAt(closedMonday)],
      ),
    ];
    List<String> run({required bool food, DateTime? date}) => filterTours(
      withFood,
      SearchCriteria(startPointId: bf, requireFood: food, date: date),
    ).map((t) => t.id).toList()..sort();

    test('„Egal“ zeigt alle', () {
      expect(run(food: false), hasLength(3));
    });

    test('„Ja, mit Einkehr“ ohne Datum: jede Tour mit Einkehr', () {
      expect(run(food: true), ['always', 'notMo']);
    });

    test('mit Datum: nur Einkehr, die an dem Tag geöffnet hat', () {
      final monday = DateTime(2026, 10, 5);
      final tuesday = DateTime(2026, 10, 6);
      expect(run(food: true, date: monday), ['always']);
      expect(run(food: true, date: tuesday), ['always', 'notMo']);
    });
  });

  group('Fahrzeit (nur bei Hin- und Rückfahrt)', () {
    // Hinfahrt 20, Rückfahrt 15 → längere Richtung 20 Min. ab Bahnhof,
    // ab Naturfreundehaus zusätzlich 15 Min. Fußweg = 35 Min.
    final rideTours = [
      fixtureTour(id: 'ride', type: TourType.rideBothWays),
      fixtureTour(
        id: 'unknown',
        type: TourType.rideBothWays,
        ride: const RideEstimate(),
      ),
    ];
    List<String> run(String start, RideChoice r) => filterTours(
      rideTours,
      SearchCriteria(
        startPointId: start,
        tourType: TourType.rideBothWays,
        ride: r,
      ),
    ).map((t) => t.id).toList();

    test('ab Bahnhof', () {
      expect(run(bf, RideChoice.upTo30), ['ride']);
      expect(run(bf, RideChoice.any), hasLength(2));
    });

    test('ab Naturfreundehaus inkl. Fußweg', () {
      expect(run(nfh, RideChoice.upTo30), isEmpty);
      expect(run(nfh, RideChoice.upTo60), ['ride']);
    });

    test('unbekannte Fahrzeit wird bei gesetztem Limit ausgeblendet', () {
      expect(run(bf, RideChoice.upTo90), ['ride']);
    });

    test('Fahrzeit-Frage wird nur bei Hin- und Rückfahrt gestellt', () {
      for (final t in [null, TourType.loop, TourType.walkOutRideBack]) {
        expect(
          SearchCriteria(startPointId: bf, tourType: t).asksRideTime,
          isFalse,
        );
      }
    });

    test('Fahrzeit-Antwort wirkt nicht auf andere Tourenarten', () {
      const c = SearchCriteria(startPointId: bf, ride: RideChoice.upTo30);
      expect(filterTours(tours, c), hasLength(4));
    });
  });

  test('oneWayTravelMin je Tourenart', () {
    final bahnhof = startPointById(bf);
    final haus = startPointById(nfh);
    expect(oneWayTravelMin(tours[0], haus), 0);
    expect(oneWayTravelMin(tours[2], bahnhof), 10);
    expect(oneWayTravelMin(tours[2], haus), 25);
    expect(oneWayTravelMin(tours[4], bahnhof), 20);
  });

  test('Sortierung nach Gehzeit', () {
    final sorted = filterTours([
      fixtureTour(id: 'b', type: TourType.loop, durationMin: 200),
      fixtureTour(id: 'a', type: TourType.loop, durationMin: 60),
    ], const SearchCriteria(startPointId: bf));
    expect(sorted.map((t) => t.id), ['a', 'b']);
  });
}
