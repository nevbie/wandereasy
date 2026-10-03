import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/choice_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../tour/domain/start_point.dart';
import '../data/start_point_store.dart';
import 'start_point_text.dart';

/// Startpunkt-Wahl (SPEC 5.2): zwei große Karten. Ein Tipp wählt und
/// führt zurück.
class StartPointScreen extends ConsumerWidget {
  const StartPointScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(startPointProvider);

    Future<void> choose(String id) async {
      await ref.read(startPointProvider.notifier).select(id);
      if (!context.mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.home);
      }
    }

    return AppPage(
      title: l10n.startPointTitle,
      // Beim allerersten Start gibt es nichts, wohin man zurück könnte.
      showBack: current != null && context.canPop(),
      children: [
        Text(
          l10n.startPointIntro,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        ChoiceCard(
          icon: Icons.house,
          title: l10n.startPointNfhName,
          subtitle: l10n.startPointNfhDetail,
          selected: current == StartPointIds.naturfreundehaus,
          onTap: () => choose(StartPointIds.naturfreundehaus),
        ),
        const SizedBox(height: 16),
        ChoiceCard(
          icon: Icons.train,
          title: startPointName(l10n, StartPointIds.bahnhof),
          subtitle: startPointDetail(l10n, StartPointIds.bahnhof),
          selected: current == StartPointIds.bahnhof,
          onTap: () => choose(StartPointIds.bahnhof),
        ),
      ],
    );
  }
}
