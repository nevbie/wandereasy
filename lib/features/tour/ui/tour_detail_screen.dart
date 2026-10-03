import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/icon_label.dart';
import '../../../core/widgets/section_heading.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../offline/data/offline_providers.dart';
import '../../offline/data/saved_tours_repository.dart';
import '../data/tour_providers.dart';
import '../domain/tour.dart';
import 'elevation_profile.dart';
import 'food_section.dart';
import 'tour_format.dart';
import 'tour_icons.dart';
import 'tour_map.dart';

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
        if (sceneryLabel(l10n, tour.scenery) case final scenery?)
          _IconLine(Icons.landscape, scenery),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => context.push(AppRoutes.dayPlan(tour.id)),
          child: tour.tourType == TourType.loop
              ? IconLabel(Icons.schedule, l10n.showDayPlan)
              : IconLabel(Icons.train, l10n.showConnection),
        ),
        const SizedBox(height: 16),
        _SaveForOffline(tour: tour),
        SectionHeading(l10n.mapTitle),
        TourMap(tour: tour),
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

/// Zweiter Knopf „Für unterwegs speichern“ bzw. Status „Offline verfügbar“.
class _SaveForOffline extends ConsumerWidget {
  const _SaveForOffline({required this.tour});

  final Tour tour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (ref.watch(isTourSavedProvider(tour.id))) {
      return _IconLine(Icons.offline_pin, l10n.savedOffline);
    }

    Future<void> save() async {
      await ref.read(savedToursRepositoryProvider).save(tour);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.savedSnack)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton(
          onPressed: save,
          child: IconLabel(Icons.download, l10n.saveForOffline),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.saveSizeHint(
            formatBytes(l10n, SavedToursRepository.estimateSizeBytes(tour)),
          ),
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
