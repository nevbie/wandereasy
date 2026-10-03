import 'package:flutter/material.dart';

import '../../../core/widgets/app_page.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Platzhalter (M0). Inhalt folgt in einem späteren Meilenstein.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppPage(title: l10n.searchTitle, children: const [ComingSoon()]);
  }
}
