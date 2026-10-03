import 'package:flutter_test/flutter_test.dart';
import 'package:wandern/core/geo/lat_lng.dart';
import 'package:wandern/features/tour/domain/food_place.dart';
import 'package:wandern/features/tour/domain/tour.dart';
import 'package:wandern/features/tour/domain/tour_places.dart';

import '../../helpers/tour_fixtures.dart';

void main() {
  const route = [LatLng(49.80, 9.8), LatLng(49.81, 9.8), LatLng(49.82, 9.8)];
  final base = fixtureTour(id: 't', type: TourType.walkOutRideBack);
  Tour withRoute() => Tour(
    id: base.id,
    name: base.name,
    description: '',
    tourType: base.tourType,
    startPointIds: base.startPointIds,
    difficulty: base.difficulty,
    distanceM: 2224,
    ascentM: 0,
    descentM: 0,
    durationMin: 30,
    route: route,
  );

  test('Einkehr: eigene Koordinaten, Ziel, Start, km', () {
    final t = withRoute();
    const placed = FoodPlace(
      id: 'p',
      name: 'p',
      kind: FoodKind.cafe,
      location: LatLng(1, 2),
    );
    expect(
      foodLocation(
        t,
        const TourFood(place: placed, position: FoodPosition.onRoute),
      ),
      const LatLng(1, 2),
    );
    expect(
      foodLocation(
        t,
        const TourFood(place: openEveryDay, position: FoodPosition.atEnd),
      ),
      route.last,
    );
    expect(
      foodLocation(
        t,
        const TourFood(place: openEveryDay, position: FoodPosition.atStart),
      ),
      route.first,
    );
    final atKm1 = foodLocation(
      t,
      const TourFood(
        place: openEveryDay,
        position: FoodPosition.onRoute,
        atKm: 1.112,
      ),
    )!;
    expect(atKm1.lat, closeTo(49.81, 0.0001));
  });

  test('POI ohne km und ohne Koordinaten hat keinen Ort', () {
    expect(
      poiLocation(withRoute(), const Poi(kind: PoiKind.wc, name: 'x')),
      isNull,
    );
  });

  test('Start gleich Ziel nur bei Rundweg-Geometrie', () {
    expect(startEqualsEnd(withRoute()), isFalse);
  });
}
