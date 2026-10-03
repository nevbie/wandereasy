import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/async_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../tour/domain/start_point.dart';
import '../../tour/domain/tour.dart';
import '../../tour/ui/tour_card.dart';
import '../data/search_state.dart';
import '../data/start_point_store.dart';
import 'start_point_banner.dart';

/// Vorschläge nach der Fragen-Suche (SPEC 5.3).
class SuggestionsScreen extends ConsumerWidget {
  const SuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _TourListPage(
      title: l10n.suggestionsTitle,
      tours: ref.watch(suggestionsProvider),
      emptyActions: true,
    );
  }
}

/// „Alle Touren zeigen“: Tourenliste für den gewählten Startpunkt.
class AllToursScreen extends ConsumerWidget {
  const AllToursScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _TourListPage(
      title: l10n.allToursTitle,
      tours: ref.watch(allToursForStartProvider),
      emptyActions: false,
    );
  }
}

class _TourListPage extends ConsumerWidget {
  const _TourListPage({
    required this.title,
    required this.tours,
    required this.emptyActions,
  });

  final String title;
  final AsyncValue<List<Tour>> tours;
  final bool emptyActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final startPoint = startPointById(
      ref.watch(startPointProvider) ?? StartPointIds.bahnhof,
    );

    return AppPage(
      title: title,
      top: const StartPointBanner(),
      children: switch (tours) {
        AsyncData(:final value) when value.isEmpty => [
          MessageView(l10n.noResults, icon: Icons.search_off),
          if (emptyActions) ...[
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go(AppRoutes.search),
              child: Text(l10n.changeAnswers),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.push(AppRoutes.allTours),
              child: Text(l10n.showAllTours),
            ),
          ],
        ],
        AsyncData(:final value) => [
          for (final tour in value) ...[
            TourCard(
              tour: tour,
              startPoint: startPoint,
              onTap: () => context.push(AppRoutes.tour(tour.id)),
            ),
            const SizedBox(height: 16),
          ],
        ],
        AsyncError() => [
          MessageView(l10n.loadError, icon: Icons.error_outline),
        ],
        _ => [const LoadingView()],
      },
    );
  }
}
