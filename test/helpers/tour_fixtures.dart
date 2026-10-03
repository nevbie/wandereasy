import 'package:wandern/features/tour/domain/food_place.dart';
import 'package:wandern/features/tour/domain/start_point.dart';
import 'package:wandern/features/tour/domain/tour.dart';

const allStarts = StartPointIds.all;

const openEveryDay = FoodPlace(
  id: 'open',
  name: 'Immer offen',
  kind: FoodKind.gasthaus,
  openingHours: 'Mo-Su 10:00-22:00',
);

const closedMonday = FoodPlace(
  id: 'mo',
  name: 'Montag zu',
  kind: FoodKind.gasthaus,
  restDays: [1],
);

/// Test-Tour mit sinnvollen Standardwerten.
Tour fixtureTour({
  required String id,
  required TourType type,
  List<String> startPointIds = allStarts,
  Difficulty difficulty = Difficulty.easy,
  int durationMin = 90,
  List<TourFood> food = const [],
  RideEstimate? ride,
}) => Tour(
  id: id,
  name: id,
  description: '',
  tourType: type,
  startPointIds: type == TourType.rideBothWays ? const [] : startPointIds,
  difficulty: difficulty,
  distanceM: 6000,
  ascentM: 100,
  descentM: 100,
  durationMin: durationMin,
  ride:
      ride ??
      switch (type) {
        TourType.loop => const RideEstimate(),
        TourType.walkOutRideBack => const RideEstimate(fromEndMin: 10),
        TourType.rideBothWays => const RideEstimate(
          toStartMin: 20,
          fromEndMin: 15,
        ),
      },
  food: food,
);

TourFood foodAt(FoodPlace place) =>
    TourFood(place: place, position: FoodPosition.onRoute, atKm: 3);
