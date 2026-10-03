import '../../../core/geo/lat_lng.dart';
import '../../../core/geo/route_geometry.dart';
import 'food_place.dart';
import 'tour.dart';

/// Wo liegt eine Einkehr auf der Karte? Eigene Koordinaten haben Vorrang,
/// sonst die Lage auf der Route (Start, Ziel oder km-Angabe).
LatLng? foodLocation(Tour tour, TourFood food) {
  if (food.place.location != null) return food.place.location;
  if (tour.route.isEmpty) return null;
  return switch (food.position) {
    FoodPosition.atStart => tour.route.first,
    FoodPosition.atEnd => tour.route.last,
    FoodPosition.onRoute =>
      food.atKm == null
          ? null
          : positionAtDistance(tour.route, food.atKm! * 1000),
  };
}

/// Wo liegt ein POI auf der Karte?
LatLng? poiLocation(Tour tour, Poi poi) {
  if (poi.location != null) return poi.location;
  if (tour.route.isEmpty || poi.atKm == null) return null;
  return positionAtDistance(tour.route, poi.atKm! * 1000);
}

/// Start und Ziel liegen so nah beieinander, dass ein Symbol genügt.
bool startEqualsEnd(Tour tour) =>
    tour.route.length >= 2 &&
    distanceM(tour.route.first, tour.route.last) < 100;

/// Einkehr gilt als „am Schluss“, wenn sie im letzten Drittel liegt …
const double lateFoodShare = 0.66;

/// … oder höchstens so viele km vor dem Ziel.
const double lateFoodLastKm = 2;

/// Liegt die Einkehr am Ziel oder im letzten Teil der Strecke?
/// (Wunsch des Vereins: Einkehr lieber zum Schluss.)
bool isLateFood(Tour tour, TourFood food) {
  switch (food.position) {
    case FoodPosition.atEnd:
      return true;
    case FoodPosition.atStart:
      return false;
    case FoodPosition.onRoute:
      final at = food.atKm;
      if (at == null) return false;
      final total = tour.distanceM / 1000;
      return at >= total * lateFoodShare || total - at <= lateFoodLastKm;
  }
}
