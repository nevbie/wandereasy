import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/icon_label.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../search/data/search_state.dart';
import '../../tour/ui/tour_format.dart';
import '../data/offline_providers.dart';
import '../data/saved_tours_repository.dart';

/// Meine Touren (SPEC 5.6): gespeicherte Touren mit Speicherstatus.
class MyToursScreen extends ConsumerWidget {
  const MyToursScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return AppPage(
      title: l10n.myToursTitle,
      children: switch (ref.watch(savedToursProvider)) {
        AsyncData(:final value) when value.isEmpty => [
          MessageView(l10n.myToursEmpty),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              ref.read(searchAnswersProvider.notifier).reset();
              context.go(AppRoutes.search);
            },
            child: IconLabel(Icons.search, l10n.homeSearchHike),
          ),
        ],
        AsyncData(:final value) => [
          for (final saved in value) ...[
            _SavedTourCard(saved: saved),
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

class _SavedTourCard extends ConsumerWidget {
  const _SavedTourCard({required this.saved});

  final SavedTour saved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tour = saved.tour;

    Future<void> confirmDelete() async {
      final yes = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.deleteTourTitle),
          content: Text(l10n.deleteTourMessage(tour.name)),
          actionsOverflowDirection: VerticalDirection.up,
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.noGoBack),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.deleteYes),
            ),
          ],
        ),
      );
      if (yes ?? false) {
        await ref.read(savedToursRepositoryProvider).delete(tour.id);
      }
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(tour.name, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(tourSummary(l10n, tour), style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.offline_pin, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.savedOffline,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.push(AppRoutes.navigation(tour.id)),
              child: IconLabel(Icons.directions_walk, l10n.startHike),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.push(AppRoutes.myTour(tour.id)),
              child: IconLabel(Icons.map, l10n.viewTour),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: confirmDelete,
              child: IconLabel(Icons.delete_outline, l10n.deleteTour),
            ),
          ],
        ),
      ),
    );
  }
}
