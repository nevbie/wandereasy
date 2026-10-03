import 'package:flutter_test/flutter_test.dart';
import 'package:wandern/features/search/domain/search_criteria.dart';
import 'package:wandern/features/search/domain/tour_filter.dart';
import 'package:wandern/features/tour/domain/food_place.dart';
import 'package:wandern/features/tour/domain/start_point.dart';
import 'package:wandern/features/tour/domain/tour.dart';
import 'package:wandern/features/tour/domain/tour_places.dart';

/// Tour mit frei wählbaren Werten für die Vorschlagsregeln.
Tour tour(
  String id, {
  TourType type = TourType.loop,
  double km = 10,
  double ascent = 100,
  Scenery scenery = Scenery.normal,
  List<TourFood> food = const [],
  RideEstimate ride = const RideEstimate(),
  int durationMin = 180,
}) => Tour(
  id: id,
  name: id,
  description: '',
  tourType: type,
  startPointIds: StartPointIds.all,
  difficulty: Difficulty.medium,
  distanceM: km * 1000,
  ascentM: ascent,
  descentM: ascent,
  durationMin: durationMin,
  scenery: scenery,
  food: food,
  ride: ride,
);

const place = FoodPlace(id: 'p', name: 'p', kind: FoodKind.gasthaus);

TourFood onRoute(double km) =>
    TourFood(place: place, position: FoodPosition.onRoute, atKm: km);

const atEnd = TourFood(place: place, position: FoodPosition.atEnd);

const bf = StartPointIds.bahnhof;
const nfh = StartPointIds.naturfreundehaus;

List<String> ids(Iterable<Tour> tours, [SearchCriteria? c]) => filterTours(
  tours,
  c ?? const SearchCriteria(startPointId: bf),
).map((t) => t.id).toList();

void main() {
  group('Länge: bis 20 km, je nach Höhenmetern weniger', () {
    test('Leistungskilometer = km + Hm/100', () {
      expect(effortKm(tour('t', km: 15, ascent: 500)), 20);
    });

    test('Grenzfälle', () {
      expect(withinLengthLimit(tour('a', km: 20, ascent: 0)), isTrue);
      expect(withinLengthLimit(tour('b', km: 20.5, ascent: 0)), isFalse);
      expect(withinLengthLimit(tour('c', km: 18, ascent: 200)), isTrue);
      expect(withinLengthLimit(tour('d', km: 18, ascent: 250)), isFalse);
      expect(withinLengthLimit(tour('e', km: 15, ascent: 500)), isTrue);
      expect(withinLengthLimit(tour('f', km: 15, ascent: 600)), isFalse);
    });

    test('zu lange Touren fehlen in Vorschlägen, nicht in „Alle Touren“', () {
      final all = [tour('ok', km: 16, ascent: 300), tour('lang', km: 22)];
      expect(ids(all), ['ok']);
      expect(
        filterTours(
          all,
          const SearchCriteria(startPointId: bf, ride: RideChoice.any),
          limitLength: false,
        ).map((t) => t.id),
        containsAll(['ok', 'lang']),
      );
    });

    test('„Länger als 4 Stunden“ findet lange Touren bis zur Grenze', () {
      final all = [
        tour('kurz', durationMin: 120),
        tour('lang', km: 18, ascent: 150, durationMin: 300),
      ];
      expect(
        ids(
          all,
          const SearchCriteria(
            startPointId: bf,
            duration: DurationChoice.longer,
          ),
        ),
        ['lang'],
      );
    });
  });

  group('Einkehr eher am Schluss', () {
    final t = tour('t', km: 12);
    test('am Ziel, im letzten Drittel oder in den letzten 2 km', () {
      expect(isLateFood(t, atEnd), isTrue);
      expect(isLateFood(t, onRoute(8)), isTrue); // ≥ 66 %
      expect(isLateFood(t, onRoute(7.9)), isFalse);
      expect(isLateFood(tour('lang', km: 30), onRoute(28)), isTrue);
      expect(isLateFood(t, onRoute(3)), isFalse);
      expect(
        isLateFood(
          t,
          const TourFood(place: place, position: FoodPosition.atStart),
        ),
        isFalse,
      );
    });

    test('Einkehr am Schluss steht vor Einkehr unterwegs', () {
      final all = [
        tour('mitte', food: [onRoute(4)]),
        tour('schluss', food: [atEnd]),
        tour('ohne'),
      ];
      expect(ids(all), ['schluss', 'mitte', 'ohne']);
    });
  });

  group('Landschaft', () {
    test('schöne Landschaft zählt mehr als Einkehr', () {
      final all = [
        tour('einkehr', food: [atEnd]),
        tour('schoen', scenery: Scenery.outstanding),
        tour('nett', scenery: Scenery.nice),
      ];
      expect(ids(all), ['schoen', 'nett', 'einkehr']);
    });
  });

  group('Anfahrt: bis 1 Std., lieber ohne Umsteigen', () {
    Tour ride(String id, int min, int transfers) => tour(
      id,
      type: TourType.rideBothWays,
      ride: RideEstimate(
        toStartMin: min,
        fromEndMin: min,
        toStartTransfers: transfers,
        fromEndTransfers: transfers,
      ),
    );

    test('Standard: höchstens 60 Min. – auch ohne Fahrzeit-Frage', () {
      final all = [
        ride('nah', 30, 0),
        ride('weit', 55, 0),
        ride('zu weit', 70, 0),
      ];
      expect(ids(all), containsAll(['nah', 'weit']));
      expect(ids(all), isNot(contains('zu weit')));
      // ab Naturfreundehaus zählen 15 Min. Fußweg dazu
      expect(ids(all, const SearchCriteria(startPointId: nfh)), ['nah']);
    });

    test('„Egal“ hebt die Grenze auf', () {
      expect(
        ids([
          ride('zu weit', 70, 0),
        ], const SearchCriteria(startPointId: bf, ride: RideChoice.any)),
        ['zu weit'],
      );
    });

    test('ohne Umsteigen steht vorn, mehrfaches Umsteigen hinten', () {
      final all = [
        ride('einmal', 40, 1),
        ride('direkt', 40, 0),
        ride('zweimal', 40, 2),
      ];
      expect(ids(all), ['direkt', 'einmal', 'zweimal']);
      expect(maxTransfers(all[1]), 0);
    });

    test('Rundwege werden durch die Fahrzeit nicht eingeschränkt', () {
      expect(
        ids([
          tour('runde'),
        ], const SearchCriteria(startPointId: bf, ride: RideChoice.upTo30)),
        ['runde'],
      );
    });
  });
}
