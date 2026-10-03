import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// „Wird geladen …“ mit Fortschrittsanzeige – nie ein leerer Bildschirm.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Column(
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context).loading,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    ),
  );
}

/// Fehlermeldung, die sagt, was zu tun ist.
class MessageView extends StatelessWidget {
  const MessageView(this.message, {super.key, this.icon = Icons.info_outline});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 32),
      const SizedBox(width: 12),
      Expanded(
        child: Text(message, style: Theme.of(context).textTheme.bodyLarge),
      ),
    ],
  );
}
