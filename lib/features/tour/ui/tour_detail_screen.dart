import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/icon_label.dart';
import '../../../core/widgets/section_heading.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/tour_providers.dart';
import '../domain/tour.dart';
import 'elevation_profile.dart';
import 'food_section.dart';
import 'tour_format.dart';
import 'tour_icons.dart';

/// Tour-Detail (SPEC 5.4). Karte folgt in M2.
class TourDetailScreen extends ConsumerWidget {
  const TourDetailScreen({super.key, required this.tourId});

  final String tourId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return switch (ref.watch(tourByIdProvider(tourId))) {
      AsyncData(value: final Tour tour) => _TourDetail(tour: tour),
      AsyncData() => AppPage(
        title: l10n.allToursTitle,
        children: [MessageView(l10n.tourNotFound)],
      ),
      AsyncError() => AppPage(
        title: l10n.allToursTitle,
        children: [MessageView(l10n.loadError, icon: Icons.error_outline)],
      ),
      _ => AppPage(title: l10n.loading, children: const [LoadingView()]),
    };
  }
}

class _TourDetail extends StatelessWidget {
  const _TourDetail({required this.tour});

  final Tour tour;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyMedium;
    final onTheWay = tour.pois.where((p) => p.kind != PoiKind.shortcut);
    final shortcuts = tour.pois.where((p) => p.kind == PoiKind.shortcut);

    return AppPage(
      title: tour.name,
      children: [
        if (tour.isDemo) ...[
          Text(
            l10n.demoBadge,
            style: body?.copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          tourSummary(l10n, tour),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _IconLine(
          tourTypeIcon(tour.tourType),
          tourTypeLabel(l10n, tour.tourType),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => context.push(AppRoutes.dayPlan(tour.id)),
          child: tour.tourType == TourType.loop
              ? IconLabel(Icons.schedule, l10n.showDayPlan)
              : IconLabel(Icons.train, l10n.showConnection),
        ),
        SectionHeading(l10n.descriptionTitle),
        Text(tour.description, style: body),
        SectionHeading(l10n.elevationTitle),
        ElevationProfile(profile: tour.profile),
        SectionHeading(l10n.foodTitle),
        FoodSection(food: tour.food),
        if (onTheWay.isNotEmpty) ...[
          SectionHeading(l10n.onTheWayTitle),
          for (final p in onTheWay) _PoiLine(poi: p),
        ],
        if (tour.surfaceNotes != null) ...[
          SectionHeading(l10n.surfaceTitle),
          Text(tour.surfaceNotes!, style: body),
        ],
        if (tour.warnings.isNotEmpty) ...[
          SectionHeading(l10n.warningsTitle),
          for (final w in tour.warnings) _IconLine(Icons.warning_amber, w),
        ],
        if (shortcuts.isNotEmpty) ...[
          SectionHeading(l10n.shortcutsTitle),
          for (final p in shortcuts) _PoiLine(poi: p),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 26),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    ),
  );
}

class _PoiLine extends StatelessWidget {
  const _PoiLine({required this.poi});

  final Poi poi;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final parts = [
      if (poi.atKm != null) l10n.atKm(formatKmValue(poi.atKm!)),
      poi.name,
      ?poi.note,
    ];
    return _IconLine(poiIcon(poi.kind), parts.join(' · '));
  }
}
