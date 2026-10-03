import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../tour/domain/start_point.dart';
import '../data/start_point_store.dart';
import 'start_point_text.dart';

/// „Start: Naturfreundehaus Veitshöchheim · ändern“ (SPEC 5.2).
class StartPointBanner extends ConsumerWidget {
  const StartPointBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final id = ref.watch(startPointProvider) ?? StartPointIds.bahnhof;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 4, top: 4, bottom: 4),
        child: Row(
          children: [
            Icon(Icons.place, color: scheme.onSecondaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.startPointHeader(startPointName(l10n, id)),
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSecondaryContainer),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              label: l10n.changeStartPointSemantics,
              button: true,
              excludeSemantics: true,
              child: TextButton(
                onPressed: () => context.push(AppRoutes.startPoint),
                child: Text(l10n.change),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
