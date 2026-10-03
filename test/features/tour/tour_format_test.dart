import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandern/features/tour/domain/food_place.dart';
import 'package:wandern/features/tour/domain/tour.dart';
import 'package:wandern/features/tour/ui/tour_format.dart';
import 'package:wandern/l10n/generated/app_localizations.dart';

import '../../helpers/tour_fixtures.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('de'));

  test('Gehzeit in Std./Min.', () {
    expect(formatDuration(l10n, 7), '7 Min.');
    expect(formatDuration(l10n, 44), '45 Min.');
    expect(formatDuration(l10n, 60), '1 Std.');
    expect(formatDuration(l10n, 150), '2 ½ Std.');
    expect(formatDuration(l10n, 140), '2 ¼ Std.');
    expect(formatDuration(l10n, 170), '2 ¾ Std.');
    expect(formatDuration(l10n, 236), '4 Std.');
  });

  test('Strecke und Höhenmeter', () {
    expect(formatKm(l10n, 9100), '9 km');
    expect(formatKm(l10n, 9300), '9,5 km');
    expect(formatKm(l10n, 1240), '1,2 km');
    expect(formatAscent(l10n, 118), '120 m bergauf');
  });

  test('Kurzfazit wie in SPEC 4', () {
    final tour = Tour(
      id: 't',
      name: 't',
      description: '',
      tourType: TourType.loop,
      startPointIds: const [],
      difficulty: Difficulty.easy,
      distanceM: 9000,
      ascentM: 120,
      descentM: 120,
      durationMin: 150,
      food: [foodAt(openEveryDay)],
    );
    expect(
      tourSummary(l10n, tour),
      '2 ½ Std. · leicht · 9 km · 120 m bergauf · Einkehr unterwegs',
    );
  });

  test('Kurzfazit: Einkehr am Ziel / ohne Einkehr', () {
    final atEnd = fixtureTour(
      id: 'e',
      type: TourType.loop,
      food: const [TourFood(place: openEveryDay, position: FoodPosition.atEnd)],
    );
    expect(tourSummary(l10n, atEnd), endsWith('Einkehr am Ziel'));
    final none = fixtureTour(id: 'n', type: TourType.loop);
    expect(tourSummary(l10n, none), isNot(contains('Einkehr')));
  });

  test('Datum kurz', () {
    expect(formatDateShort(l10n, DateTime(2026, 10, 10)), 'Samstag, 10.10.');
  });
}
