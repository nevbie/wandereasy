import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../domain/start_point.dart';
import '../domain/tour.dart';
import 'difficulty_badge.dart';
import 'tour_format.dart';
import 'tour_icons.dart';

/// Große Vorschlagskarte (SPEC 5.3).
// ANNAHME: Noch keine Fotos (Demo-Daten haben keine); Platz dafür folgt,
// sobald der Verein Fotos liefert.
class TourCard extends StatelessWidget {
  const TourCard({
    super.key,
    required this.tour,
    required this.startPoint,
    required this.onTap,
  });

  final Tour tour;
  final StartPoint startPoint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final body = theme.textTheme.bodyMedium;
    final hint = foodHint(l10n, tour);

    Widget line(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: body)),
        ],
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outline),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tour.isDemo)
                Text(
                  l10n.demoBadge,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              Text(tour.name, style: theme.textTheme.titleLarge),
              line(
                tourTypeIcon(tour.tourType),
                tourTypeLabel(l10n, tour.tourType),
              ),
              line(
                Icons.schedule,
                l10n.walkingTime(formatDuration(l10n, tour.durationMin)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: DifficultyBadge(tour.difficulty),
              ),
              line(Icons.train, rideText(l10n, tour, startPoint)),
              if (hint != null) line(Icons.restaurant, hint),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fahrzeit-Zeile der Karte, inkl. Fußweg zwischen Startpunkt und Bahnhof.
String rideText(AppLocalizations l10n, Tour tour, StartPoint startPoint) {
  final walk = startPoint.walkMinToStation;
  final ride = tour.ride;
  String d(int min) => formatDuration(l10n, min + walk);
  return switch (tour.tourType) {
    TourType.loop => l10n.rideNone,
    TourType.walkOutRideBack =>
      ride.fromEndMin == null ? '' : l10n.rideBack(d(ride.fromEndMin!)),
    TourType.rideBothWays =>
      ride.toStartMin == null || ride.fromEndMin == null
          ? ''
          : l10n.rideBoth(d(ride.toStartMin!), d(ride.fromEndMin!)),
  };
}
