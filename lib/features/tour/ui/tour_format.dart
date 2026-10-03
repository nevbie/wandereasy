import '../../../l10n/generated/app_localizations.dart';
import '../domain/food_place.dart';
import '../domain/tour.dart';

/// Zahl mit deutschem Dezimalkomma; ganze Zahlen ohne Nachkommastelle.
String formatDecimal(double value) {
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(1).replaceAll('.', ',');
}

/// Gehzeit in Std./Min. (SPEC 4), auf Viertelstunden gerundet,
/// z. B. „45 Min.“, „1 Std.“, „2 ½ Std.“.
String formatDuration(AppLocalizations l10n, int minutes) {
  if (minutes < 60) {
    final rounded = minutes < 10 ? minutes : (minutes / 5).round() * 5;
    return l10n.durationMinutes(rounded);
  }
  final quarters = (minutes / 15).round();
  final hours = quarters ~/ 4;
  const fractions = ['', ' ¼', ' ½', ' ¾'];
  return l10n.durationHours('$hours${fractions[quarters % 4]}');
}

/// Strecke in km, auf halbe km gerundet (unter 2 km auf 0,1 km).
String formatKm(AppLocalizations l10n, double meters) {
  final km = meters / 1000;
  final rounded = km < 2 ? (km * 10).round() / 10 : (km * 2).round() / 2;
  return l10n.distanceKm(formatDecimal(rounded));
}

/// Kilometerangabe ohne Einheit („6“, „2,5“).
String formatKmValue(double km) => formatDecimal((km * 10).round() / 10);

String formatAscent(AppLocalizations l10n, double meters) =>
    l10n.ascentUp(((meters / 10).round() * 10));

String difficultyLabel(AppLocalizations l10n, Difficulty d) =>
    l10n.difficulty(d.name);

String tourTypeLabel(AppLocalizations l10n, TourType t) =>
    l10n.tourTypeShort(t.name);

String weekdayName(AppLocalizations l10n, int weekday) =>
    l10n.weekday('$weekday');

String formatDateShort(AppLocalizations l10n, DateTime d) =>
    l10n.dateShort(weekdayName(l10n, d.weekday), d.day, d.month);

/// Kurzfazit (SPEC 4): „2 ½ Std. · leicht · 9 km · 120 m bergauf ·
/// Einkehr unterwegs“.
String tourSummary(AppLocalizations l10n, Tour tour) {
  final parts = [
    formatDuration(l10n, tour.durationMin),
    difficultyLabel(l10n, tour.difficulty),
    formatKm(l10n, tour.distanceM),
    formatAscent(l10n, tour.ascentM),
  ];
  if (tour.food.any((f) => f.position == FoodPosition.onRoute)) {
    parts.add(l10n.summaryFoodOnRoute);
  } else if (tour.hasFood) {
    parts.add(l10n.summaryFoodAtEnd);
  }
  return parts.join(' · ');
}

/// Lage einer Einkehr auf der Tour („bei km 6“, „am Ziel“).
String foodPositionLabel(AppLocalizations l10n, TourFood f) =>
    switch (f.position) {
      FoodPosition.atEnd => l10n.foodAtEnd,
      FoodPosition.atStart => l10n.foodAtStart,
      FoodPosition.onRoute =>
        f.atKm == null ? '' : l10n.foodAtKm(formatKmValue(f.atKm!)),
    };

/// Einkehr-Hinweis für die Vorschlagskarte (SPEC 5.3).
String? foodHint(AppLocalizations l10n, Tour tour) {
  if (!tour.hasFood) return null;
  final f = tour.food.first;
  return switch (f.position) {
    FoodPosition.atEnd => l10n.foodHintAtEnd(f.place.name),
    FoodPosition.atStart => l10n.foodHintAtStart(f.place.name),
    FoodPosition.onRoute => l10n.foodHintAtKm(
      f.place.name,
      formatKmValue(f.atKm ?? 0),
    ),
  };
}

/// Speichergröße, z. B. „40 KB“ oder „2,5 MB“.
String formatBytes(AppLocalizations l10n, int bytes) {
  if (bytes < 1000 * 1000) return l10n.sizeKb((bytes / 1000).ceil());
  return l10n.sizeMb(formatDecimal((bytes / 100000).round() / 10));
}
