import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/icon_label.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/tour_providers.dart';
import '../domain/food_place.dart';
import '../domain/opening.dart';
import 'tour_format.dart';
import 'tour_icons.dart';

/// Block „Einkehren“ im Tour-Detail (SPEC 5.11).
class FoodSection extends ConsumerWidget {
  const FoodSection({super.key, required this.food});

  final List<TourFood> food;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final date = ref.watch(plannedDateProvider);

    if (food.isEmpty) {
      return Text(l10n.foodNone, style: theme.textTheme.bodyMedium);
    }

    Future<void> pickDate() async {
      final today = DateUtils.dateOnly(DateTime.now());
      final picked = await showDatePicker(
        context: context,
        initialDate: date.isBefore(today) ? today : date,
        firstDate: today,
        lastDate: today.add(const Duration(days: 365)),
      );
      if (picked != null) ref.read(plannedDateProvider.notifier).set(picked);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.plannedDay(formatDateShort(l10n, date)),
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            onPressed: pickDate,
            child: IconLabel(Icons.calendar_month, l10n.changeDay),
          ),
        ),
        const SizedBox(height: 16),
        for (final f in food) ...[
          FoodPlaceCard(tourFood: f, date: date),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class FoodPlaceCard extends StatelessWidget {
  const FoodPlaceCard({super.key, required this.tourFood, required this.date});

  final TourFood tourFood;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final place = tourFood.place;
    final body = theme.textTheme.bodyMedium;

    final where = [
      l10n.foodKind(place.kind.name),
      foodPositionLabel(l10n, tourFood),
    ].where((s) => s.isNotEmpty).join(' · ');

    final weekday = weekdayName(l10n, date.weekday);
    final status = openingStatusOn(place, date);
    final (statusIcon, statusText, statusColor) = switch (status) {
      OpeningStatus.open => (
        Icons.check_circle,
        l10n.openOn(weekday),
        scheme.primary,
      ),
      OpeningStatus.restDay => (
        Icons.cancel,
        l10n.restDayOn(weekday),
        scheme.onSurfaceVariant,
      ),
      OpeningStatus.outOfSeason => (
        Icons.cancel,
        l10n.outOfSeasonOn(weekday),
        scheme.onSurfaceVariant,
      ),
      OpeningStatus.unknown => (
        Icons.help_outline,
        l10n.openingUnknown,
        scheme.onSurfaceVariant,
      ),
    };

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(foodIcon(place.kind), size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(place.name, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(where, style: body),
            if (tourFood.detourMin > 0)
              Text(l10n.foodDetour(tourFood.detourMin), style: body),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusText,
                    style: body?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (place.isSeasonal) ...[
              const SizedBox(height: 4),
              Text(l10n.seasonalHint, style: body),
            ],
            if (place.phone != null) ...[
              const SizedBox(height: 12),
              Semantics(
                label: l10n.callSemantics(place.name),
                button: true,
                excludeSemantics: true,
                child: OutlinedButton(
                  onPressed: () =>
                      launchUrl(Uri(scheme: 'tel', path: place.phone)),
                  child: IconLabel(Icons.phone, l10n.call),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
