import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import 'icon_label.dart';

/// Grundgerüst für jeden Bildschirm.
///
/// Statt einer `AppBar` mit fester Höhe gibt es einen Kopfbereich, der mit
/// der Schriftgröße mitwächst (SPEC 4: 200 % Schrift ohne abgeschnittenen
/// Text). „Zurück“ steht immer oben links mit sichtbarem Text, sobald es
/// eine vorherige Seite gibt.
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.children,
    this.showBack,
    this.top,
  });

  final String title;
  final List<Widget> children;

  /// `null` = automatisch, je nachdem ob zurückgegangen werden kann.
  final bool? showBack;

  /// Optionaler Bereich über der Überschrift (z. B. der gewählte Startpunkt).
  final Widget? top;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canGoBack = showBack ?? GoRouter.of(context).canPop();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (canGoBack)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: IconLabel(Icons.arrow_back, l10n.back),
                  ),
                ),
              if (canGoBack) const SizedBox(height: AppSizes.tapTargetGap),
              if (top != null) ...[top!, const SizedBox(height: 16)],
              Semantics(
                header: true,
                child: Text(title, style: theme.textTheme.headlineMedium),
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// Platzhalter-Inhalt für Bereiche, die in späteren Meilensteinen kommen.
class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key, this.showHomeButton = true});

  final bool showHomeButton;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.comingSoon, style: Theme.of(context).textTheme.bodyLarge),
        if (showHomeButton) ...[
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go('/'),
            child: IconLabel(Icons.home, l10n.toHome),
          ),
        ],
      ],
    );
  }
}
