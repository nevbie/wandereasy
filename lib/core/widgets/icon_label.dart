import 'package:flutter/material.dart';

/// Knopfinhalt aus Symbol und Text, der bei großer Schrift umbricht statt
/// abzuschneiden (`FilledButton.icon` kann das nicht).
class IconLabel extends StatelessWidget {
  const IconLabel(this.icon, this.label, {super.key, this.iconSize = 24});

  final IconData icon;
  final String label;
  final double iconSize;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: iconSize),
      const SizedBox(width: 12),
      Flexible(child: Text(label)),
    ],
  );
}
