import 'package:flutter/material.dart';

import '../../../core/widgets/app_page.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Tagesablauf / Verbindung (SPEC 5.5). Platzhalter bis M4.
class DayPlanScreen extends StatelessWidget {
  const DayPlanScreen({super.key, required this.tourId});

  final String tourId;

  @override
  Widget build(BuildContext context) => AppPage(
    title: AppLocalizations.of(context).dayPlanTitle,
    children: const [ComingSoon()],
  );
}
