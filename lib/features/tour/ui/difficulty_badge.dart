import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/tour.dart';
import 'tour_format.dart';

/// Schwierigkeit mit Farbe **und** Text (SPEC 4).
class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge(this.difficulty, {super.key});

  final Difficulty difficulty;

  static Color colorOf(Difficulty d) => switch (d) {
    Difficulty.easy => AppColors.difficultyEasy,
    Difficulty.medium => AppColors.difficultyMedium,
    Difficulty.hard => AppColors.difficultyHard,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorOf(difficulty),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Text(
          difficultyLabel(l10n, difficulty),
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
