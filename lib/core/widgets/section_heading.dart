import 'package:flutter/material.dart';

/// Überschrift eines Abschnitts, für Screenreader als Überschrift markiert.
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 32, bottom: 12),
    child: Semantics(
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    ),
  );
}
