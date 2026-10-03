import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_page.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Startseite (SPEC 5.1): Begrüßung und drei große Knöpfe.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const gap = SizedBox(height: 16);

    return AppPage(
      title: l10n.homeGreeting,
      showBack: false,
      children: [
        Text(l10n.homeIntro, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 24),
        // Hauptknopf
        _BigButton(
          primary: true,
          icon: Icons.search,
          label: l10n.homeSearchHike,
          onPressed: () => context.go(AppRoutes.search),
        ),
        gap,
        _BigButton(
          icon: Icons.groups,
          label: l10n.homeGroupHikes,
          onPressed: () => context.go(AppRoutes.groups),
        ),
        gap,
        _BigButton(
          icon: Icons.bookmark,
          label: l10n.homeMyTours,
          onPressed: () => context.go(AppRoutes.myTours),
        ),
        // Die nächste Gruppenwanderung als Karte folgt in M5.
      ],
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    const style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size(double.infinity, AppSizes.minTapTarget + 24),
      ),
      alignment: Alignment.centerLeft,
    );
    final icon = Icon(this.icon, size: 32);
    final label = Text(this.label);

    return primary
        ? FilledButton.icon(
            style: style,
            onPressed: onPressed,
            icon: icon,
            label: label,
          )
        : OutlinedButton.icon(
            style: style,
            onPressed: onPressed,
            icon: icon,
            label: label,
          );
  }
}
