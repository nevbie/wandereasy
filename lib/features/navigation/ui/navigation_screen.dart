import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/icon_label.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../tour/data/tour_providers.dart';
import '../../tour/domain/tour.dart';
import '../../tour/ui/tour_format.dart';
import '../data/navigation_controller.dart';
import 'navigation_map.dart';

/// Navigation unterwegs (SPEC 5.7).
class NavigationScreen extends ConsumerWidget {
  const NavigationScreen({super.key, required this.tourId});

  final String tourId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return switch (ref.watch(tourByIdProvider(tourId))) {
      AsyncData(value: final Tour tour) => _Navigation(tour: tour),
      AsyncData() => AppPage(
        title: l10n.navigationTitle,
        children: [MessageView(l10n.tourNotFound)],
      ),
      AsyncError() => AppPage(
        title: l10n.navigationTitle,
        children: [MessageView(l10n.loadError, icon: Icons.error_outline)],
      ),
      _ => AppPage(
        title: l10n.navigationTitle,
        children: const [LoadingView()],
      ),
    };
  }
}

class _Navigation extends ConsumerWidget {
  const _Navigation({required this.tour});

  final Tour tour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = navigationControllerProvider(tour.id);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final body = Theme.of(context).textTheme.bodyLarge;

    final List<Widget> children = switch (state.status) {
      NavStatus.intro => [
        Text(l10n.navPermissionExplain, style: body),
        const SizedBox(height: 12),
        Text(l10n.navBackgroundExplain, style: body),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => controller.start(tour),
          child: IconLabel(
            Icons.my_location,
            state.permissionGranted
                ? l10n.navStart
                : l10n.navStartWithPermission,
          ),
        ),
        if (AppConfig.enableSimulation) ...[
          const SizedBox(height: 24),
          Text(l10n.navSimulateHint, style: body),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => controller.startSimulation(tour),
            child: IconLabel(Icons.play_circle_outline, l10n.navSimulate),
          ),
        ],
      ],
      NavStatus.denied => [
        MessageView(l10n.navDenied, icon: Icons.location_disabled),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => controller.start(tour),
          child: Text(l10n.navRetry),
        ),
      ],
      NavStatus.deniedForever => [
        MessageView(l10n.navDeniedForever, icon: Icons.location_disabled),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: controller.openAppSettings,
          child: Text(l10n.navOpenSettings),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: controller.backToIntro,
          child: Text(l10n.navRetry),
        ),
      ],
      NavStatus.serviceDisabled => [
        MessageView(l10n.navServiceDisabled, icon: Icons.location_off),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: controller.openLocationSettings,
          child: Text(l10n.navOpenSettings),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => controller.start(tour),
          child: Text(l10n.navRetry),
        ),
      ],
      NavStatus.finished => [MessageView(l10n.navArrived)],
      NavStatus.waitingForFix ||
      NavStatus.running ||
      NavStatus.paused => _running(context, l10n, state, controller),
    };

    final active =
        state.status == NavStatus.running ||
        state.status == NavStatus.waitingForFix ||
        state.status == NavStatus.paused;

    return AppPage(
      title: tour.name,
      // Während der Navigation nur über „Wanderung beenden“ hinaus.
      showBack: !active,
      children: children,
    );
  }

  List<Widget> _running(
    BuildContext context,
    AppLocalizations l10n,
    NavigationViewState state,
    NavigationController controller,
  ) {
    final theme = Theme.of(context);
    final snap = state.snapshot;
    final paused = state.status == NavStatus.paused;
    final arrived = snap?.arrived ?? false;

    Future<void> confirmFinish() async {
      final yes = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.navFinishTitle),
          content: Text(l10n.navFinishMessage),
          actionsOverflowDirection: VerticalDirection.up,
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.noGoBack),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.navFinishYes),
            ),
          ],
        ),
      );
      if ((yes ?? false) && context.mounted) {
        controller.finish();
        if (context.canPop()) context.pop();
      }
    }

    return [
      if (state.simulated) ...[
        Text(
          l10n.navSimulationBadge,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
      ],
      Semantics(
        liveRegion: true,
        child: Text(
          snap == null
              ? l10n.navWaiting
              : l10n.navRemaining(formatDistance(l10n, snap.remainingM)),
          style: theme.textTheme.headlineSmall,
        ),
      ),
      if (snap?.nextTarget != null) ...[
        const SizedBox(height: 8),
        Text(
          l10n.navNextTarget(
            formatDistance(l10n, snap!.nextTargetDistanceM!),
            snap.nextTarget!.name,
          ),
          style: theme.textTheme.titleMedium,
        ),
      ],
      if (paused) ...[
        const SizedBox(height: 12),
        MessageView(l10n.navPaused, icon: Icons.pause_circle_outline),
      ] else if (state.banner != null) ...[
        const SizedBox(height: 12),
        _Banner(banner: state.banner!, active: snap?.offRoute ?? false),
      ],
      const SizedBox(height: 16),
      NavigationMap(engine: state.engine!, snapshot: snap),
      const SizedBox(height: 24),
      if (arrived)
        FilledButton(
          onPressed: confirmFinish,
          child: IconLabel(Icons.flag, l10n.navFinish),
        )
      else ...[
        OutlinedButton(
          onPressed: () => context.push(AppRoutes.shortcut(tour.id)),
          child: IconLabel(Icons.alt_route, l10n.navShortcut),
        ),
        const SizedBox(height: 12),
        if (paused)
          FilledButton(
            onPressed: controller.resume,
            child: IconLabel(Icons.play_arrow, l10n.navResume),
          )
        else
          OutlinedButton(
            onPressed: controller.pause,
            child: IconLabel(Icons.pause, l10n.navPause),
          ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: confirmFinish,
          child: IconLabel(Icons.stop_circle_outlined, l10n.navFinish),
        ),
      ],
      const SizedBox(height: 24),
    ];
  }
}

/// Warnung (rot) bzw. Hinweis. Warnungen werden vom Screenreader sofort
/// vorgelesen.
class _Banner extends StatelessWidget {
  const _Banner({required this.banner, required this.active});

  final NavBanner banner;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final warning = banner.kind == BannerKind.warning && active;
    final bg = warning ? scheme.errorContainer : scheme.secondaryContainer;
    final fg = warning ? scheme.onErrorContainer : scheme.onSecondaryContainer;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: warning ? Border.all(color: scheme.error, width: 3) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              warning ? Icons.warning_amber : Icons.info_outline,
              color: fg,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                banner.text,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
