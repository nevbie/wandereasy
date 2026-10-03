import 'package:flutter/material.dart';

import '../../../core/widgets/app_page.dart';
import '../../../l10n/generated/app_localizations.dart';

/// „Ich möchte abkürzen“ (SPEC 5.8). Platzhalter bis M4 – die Navigation
/// läuft im Hintergrund weiter.
class ShortcutScreen extends StatelessWidget {
  const ShortcutScreen({super.key, required this.tourId});

  final String tourId;

  @override
  Widget build(BuildContext context) => AppPage(
    title: AppLocalizations.of(context).shortcutTitle,
    children: const [ComingSoon(showHomeButton: false)],
  );
}
