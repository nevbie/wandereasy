import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// Rahmen mit der unteren Leiste: genau 4 Bereiche (SPEC 4 „Navigation“).
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = [
      (Icons.hiking, l10n.navHikes),
      (Icons.groups, l10n.navGroups),
      (Icons.bookmark, l10n.navMyTours),
      (Icons.help, l10n.navHelp),
    ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _BottomBar(
        items: items,
        selectedIndex: navigationShell.currentIndex,
        onSelected: (index) => navigationShell.goBranch(
          index,
          // Erneutes Tippen auf den aktiven Bereich führt zu dessen Anfang.
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

/// Eigene Leiste statt `NavigationBar`, damit die Höhe mit der Schrift
/// mitwächst und Beschriftungen immer sichtbar sind.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<(IconData, String)> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  // ANNAHME: Vier Beschriftungen nebeneinander passen bei 200 % Schrift nicht
  // auf ein Telefon. Die Leiste skaliert daher höchstens bis 130 % und
  // verkleinert notfalls, statt Text abzuschneiden (siehe DECISIONS.md).
  static const double _maxLabelScale = 1.3;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textScaler = MediaQuery.textScalerOf(context)
        .clamp(maxScaleFactor: _maxLabelScale);

    return Material(
      color: scheme.surfaceContainer,
      elevation: 3,
      child: SafeArea(
        top: false,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            // IntrinsicHeight: alle Felder gleich hoch, Leiste nur so hoch
            // wie nötig.
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: _BottomBarItem(
                        icon: items[i].$1,
                        label: items[i].$2,
                        selected: i == selectedIndex,
                        onTap: () => onSelected(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBarItem extends StatelessWidget {
  const _BottomBarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Semantics(
        selected: selected,
        button: true,
        excludeSemantics: true,
        label: label,
        child: Material(
          color: selected ? scheme.primaryContainer : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: selected
                ? BorderSide(color: scheme.primary, width: 2)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSizes.minTapTarget + 8,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: fg, size: 28),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: fg,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
