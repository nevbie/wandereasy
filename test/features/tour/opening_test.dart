import 'package:flutter_test/flutter_test.dart';
import 'package:wandern/features/tour/domain/food_place.dart';
import 'package:wandern/features/tour/domain/opening.dart';

void main() {
  // 2026-10-05 ist ein Montag.
  DateTime day(int weekday) => DateTime(2026, 10, 4 + weekday);

  FoodPlace place({
    String? hours,
    List<int> rest = const [],
    String? from,
    String? to,
  }) => FoodPlace(
    id: 'x',
    name: 'x',
    kind: FoodKind.gasthaus,
    openingHours: hours,
    restDays: rest,
    seasonFrom: from == null ? null : MonthDay.parse(from),
    seasonTo: to == null ? null : MonthDay.parse(to),
  );

  test('Testdaten: day(1) ist Montag, day(7) Sonntag', () {
    expect(day(1).weekday, DateTime.monday);
    expect(day(7).weekday, DateTime.sunday);
  });

  group('Ruhetag', () {
    test('Ruhetag Montag', () {
      final p = place(rest: [1]);
      expect(openingStatusOn(p, day(1)), OpeningStatus.restDay);
      expect(openingStatusOn(p, day(2)), OpeningStatus.open);
    });

    test('ohne Angaben: unbekannt', () {
      expect(openingStatusOn(place(), day(3)), OpeningStatus.unknown);
    });
  });

  group('Öffnungszeiten (OSM)', () {
    test('Tu-Su', () {
      final p = place(hours: 'Tu-Su 11:00-22:00');
      expect(openingStatusOn(p, day(1)), OpeningStatus.restDay);
      for (var d = 2; d <= 7; d++) {
        expect(openingStatusOn(p, day(d)), OpeningStatus.open);
      }
    });

    test('mehrere Regeln, off überschreibt', () {
      expect(parseOpenWeekdays('Mo-Fr 11:00-14:00,17:00-22:00; We off'), {
        1,
        2,
        4,
        5,
      });
      expect(parseOpenWeekdays('Sa,Su 10:00-18:00; PH off'), {6, 7});
    });

    test('Bereich über das Wochenende', () {
      expect(parseOpenWeekdays('Fr-Mo 12:00-20:00'), {5, 6, 7, 1});
    });

    test('24/7', () {
      expect(parseOpenWeekdays('24/7'), hasLength(7));
    });

    test('nicht lesbare Angaben ergeben „unbekannt“', () {
      expect(parseOpenWeekdays('Apr-Oct Mo-Su 10:00-18:00'), isNull);
      expect(parseOpenWeekdays('Mo-Fr nach Vereinbarung'), isNull);
      expect(
        openingStatusOn(place(hours: 'nach Absprache'), day(2)),
        OpeningStatus.unknown,
      );
    });

    test('Ruhetag hat Vorrang vor Öffnungszeiten', () {
      final p = place(hours: 'Mo-Su 10:00-22:00', rest: [3]);
      expect(openingStatusOn(p, day(3)), OpeningStatus.restDay);
    });
  });

  group('Saison', () {
    test('Häcker im Herbst', () {
      final p = place(hours: 'Th-Su 15:00-22:00', from: '09-01', to: '11-15');
      expect(
        openingStatusOn(p, DateTime(2026, 10, 9)), // Freitag
        OpeningStatus.open,
      );
      expect(
        openingStatusOn(p, DateTime(2026, 10, 6)), // Dienstag
        OpeningStatus.restDay,
      );
      expect(
        openingStatusOn(p, DateTime(2026, 12, 4)), // Freitag
        OpeningStatus.outOfSeason,
      );
    });

    test('Saisongrenzen sind eingeschlossen', () {
      const from = MonthDay(9, 1);
      const to = MonthDay(11, 15);
      expect(isInSeason(const MonthDay(9, 1), from, to), isTrue);
      expect(isInSeason(const MonthDay(11, 15), from, to), isTrue);
      expect(isInSeason(const MonthDay(8, 31), from, to), isFalse);
      expect(isInSeason(const MonthDay(11, 16), from, to), isFalse);
    });

    test('Saison über den Jahreswechsel', () {
      const from = MonthDay(11, 1);
      const to = MonthDay(2, 28);
      expect(isInSeason(const MonthDay(12, 24), from, to), isTrue);
      expect(isInSeason(const MonthDay(1, 10), from, to), isTrue);
      expect(isInSeason(const MonthDay(6, 1), from, to), isFalse);
    });
  });
}
