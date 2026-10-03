import 'package:flutter/material.dart';

import '../../../core/widgets/app_page.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Navigation unterwegs (SPEC 5.7). Platzhalter bis M3.
class NavigationScreen extends StatelessWidget {
  const NavigationScreen({super.key, required this.tourId});

  final String tourId;

  @override
  Widget build(BuildContext context) => AppPage(
    title: AppLocalizations.of(context).navigationTitle,
    children: const [ComingSoon()],
  );
}
