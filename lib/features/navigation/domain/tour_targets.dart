import '../../tour/domain/food_place.dart';
import '../../tour/domain/tour.dart';
import 'navigation_engine.dart';
import 'route_matcher.dart';

/// Einkehr und POIs einer Tour als Ziele mit Lage auf der Route.
/// Abkürzungen sind keine Ziele.
List<RouteTarget> tourTargets(Tour tour, RouteMatcher matcher) {
  final targets = <RouteTarget>[];
  for (final f in tour.food) {
    final along = switch (f.position) {
      FoodPosition.atStart => null,
      FoodPosition.atEnd => matcher.totalM,
      FoodPosition.onRoute =>
        f.atKm != null
            ? f.atKm! * 1000
            : f.place.location == null
            ? null
            : matcher.match(f.place.location!).alongM,
    };
    if (along != null) {
      targets.add(
        RouteTarget(name: f.place.name, kind: TargetKind.food, alongM: along),
      );
    }
  }
  for (final p in tour.pois) {
    if (p.kind == PoiKind.shortcut) continue;
    final along = p.atKm != null
        ? p.atKm! * 1000
        : p.location == null
        ? null
        : matcher.match(p.location!).alongM;
    if (along != null) {
      targets.add(
        RouteTarget(name: p.name, kind: TargetKind.poi, alongM: along),
      );
    }
  }
  return targets;
}
