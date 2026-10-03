import 'package:flutter/material.dart';

import '../domain/food_place.dart';
import '../domain/tour.dart';

IconData tourTypeIcon(TourType t) => switch (t) {
  TourType.loop => Icons.loop,
  TourType.walkOutRideBack => Icons.directions_walk,
  TourType.rideBothWays => Icons.train,
};

IconData poiIcon(PoiKind k) => switch (k) {
  PoiKind.wc => Icons.wc,
  PoiKind.bench => Icons.chair_alt,
  PoiKind.viewpoint => Icons.landscape,
  PoiKind.shortcut => Icons.alt_route,
  PoiKind.info => Icons.info_outline,
};

IconData foodIcon(FoodKind k) => switch (k) {
  FoodKind.cafe => Icons.local_cafe,
  FoodKind.biergarten => Icons.sports_bar,
  FoodKind.haeckerwirtschaft => Icons.wine_bar,
  FoodKind.huette => Icons.cabin,
  FoodKind.gasthaus || FoodKind.other => Icons.restaurant,
};
