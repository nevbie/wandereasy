import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/choice_card.dart';
import '../../../core/widgets/icon_label.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../tour/domain/tour.dart';
import '../data/search_state.dart';
import '../domain/search_criteria.dart';
import 'start_point_banner.dart';

class QuestionOption<T> {
  const QuestionOption(this.value, this.icon, this.label);

  final T value;
  final IconData icon;
  final String label;
}

/// Gerüst für eine Frage: Startpunkt oben, Auswahlkarten, Hauptknopf
/// „Weiter“ (SPEC 5.2).
class QuestionScaffold<T> extends ConsumerWidget {
  const QuestionScaffold({
    super.key,
    required this.step,
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelect,
    required this.nextRoute,
    this.showAllToursLink = false,
  });

  final int step;
  final String title;
  final List<QuestionOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelect;
  final String nextRoute;
  final bool showAllToursLink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final criteria = ref.watch(searchAnswersProvider);
    final total = criteria.asksRideTime ? 5 : 4;
    final isLast = nextRoute == AppRoutes.suggestions;

    return AppPage(
      title: title,
      top: const StartPointBanner(),
      children: [
        Text(
          l10n.questionProgress(step, total),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        for (final o in options) ...[
          ChoiceCard(
            icon: o.icon,
            title: o.label,
            selected: o.value == selected,
            onTap: () => onSelect(o.value),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => context.push(nextRoute),
          child: IconLabel(
            isLast ? Icons.search : Icons.arrow_forward,
            isLast ? l10n.showSuggestions : l10n.next,
          ),
        ),
        if (showAllToursLink) ...[
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.push(AppRoutes.allTours),
            child: Text(l10n.showAllTours),
          ),
        ],
      ],
    );
  }
}

class TourTypeQuestion extends ConsumerWidget {
  const TourTypeQuestion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return QuestionScaffold<TourType?>(
      step: 1,
      title: l10n.qTypeTitle,
      showAllToursLink: true,
      options: [
        QuestionOption(TourType.loop, Icons.loop, l10n.typeLoopLong),
        QuestionOption(
          TourType.walkOutRideBack,
          Icons.directions_walk,
          l10n.typeWalkOutLong,
        ),
        QuestionOption(
          TourType.rideBothWays,
          Icons.train,
          l10n.typeRideBothLong,
        ),
        QuestionOption(null, Icons.all_inclusive, l10n.anyOption),
      ],
      selected: ref.watch(searchAnswersProvider).tourType,
      onSelect: ref.read(searchAnswersProvider.notifier).setTourType,
      nextRoute: AppRoutes.searchDuration,
    );
  }
}

class DurationQuestion extends ConsumerWidget {
  const DurationQuestion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return QuestionScaffold<DurationChoice>(
      step: 2,
      title: l10n.qDurationTitle,
      options: [
        QuestionOption(DurationChoice.upTo2h, Icons.timer, l10n.durationUpTo2h),
        QuestionOption(
          DurationChoice.from2To4h,
          Icons.schedule,
          l10n.duration2To4h,
        ),
        QuestionOption(
          DurationChoice.longer,
          Icons.more_time,
          l10n.durationLonger,
        ),
        QuestionOption(DurationChoice.any, Icons.all_inclusive, l10n.anyOption),
      ],
      selected: ref.watch(searchAnswersProvider).duration,
      onSelect: ref.read(searchAnswersProvider.notifier).setDuration,
      nextRoute: AppRoutes.searchEffort,
    );
  }
}

class EffortQuestion extends ConsumerWidget {
  const EffortQuestion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return QuestionScaffold<EffortChoice>(
      step: 3,
      title: l10n.qEffortTitle,
      options: [
        QuestionOption(
          EffortChoice.easy,
          Icons.sentiment_satisfied,
          l10n.effortEasy,
        ),
        QuestionOption(
          EffortChoice.medium,
          Icons.trending_up,
          l10n.effortMedium,
        ),
        QuestionOption(EffortChoice.any, Icons.all_inclusive, l10n.anyOption),
      ],
      selected: ref.watch(searchAnswersProvider).effort,
      onSelect: ref.read(searchAnswersProvider.notifier).setEffort,
      nextRoute: AppRoutes.searchFood,
    );
  }
}

class FoodQuestion extends ConsumerWidget {
  const FoodQuestion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final answers = ref.watch(searchAnswersProvider);
    return QuestionScaffold<bool>(
      step: 4,
      title: l10n.qFoodTitle,
      options: [
        QuestionOption(true, Icons.restaurant, l10n.foodYes),
        QuestionOption(false, Icons.all_inclusive, l10n.anyOption),
      ],
      selected: answers.requireFood,
      onSelect: ref.read(searchAnswersProvider.notifier).setRequireFood,
      nextRoute: answers.asksRideTime
          ? AppRoutes.searchRide
          : AppRoutes.suggestions,
    );
  }
}

class RideQuestion extends ConsumerWidget {
  const RideQuestion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return QuestionScaffold<RideChoice>(
      step: 5,
      title: l10n.qRideTitle,
      options: [
        for (final c in [
          RideChoice.upTo30,
          RideChoice.upTo60,
          RideChoice.upTo90,
        ])
          QuestionOption(c, Icons.train, l10n.rideUpTo(c.maxMin!)),
        QuestionOption(RideChoice.any, Icons.all_inclusive, l10n.anyOption),
      ],
      selected: ref.watch(searchAnswersProvider).ride,
      onSelect: ref.read(searchAnswersProvider.notifier).setRide,
      nextRoute: AppRoutes.suggestions,
    );
  }
}
