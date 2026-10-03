import 'food_place.dart';

/// Ergebnis der Öffnungsprüfung für einen Tag.
enum OpeningStatus {
  /// Laut Daten an diesem Tag geöffnet.
  open,

  /// Regulärer Ruhetag.
  restDay,

  /// Außerhalb der Saison (z. B. Häckerwirtschaft).
  outOfSeason,

  /// Keine verlässlichen Angaben – „bitte vorher prüfen“.
  unknown,
}

/// Prüft, ob [place] am Tag [date] geöffnet hat (SPEC 5.11).
///
/// Reihenfolge: Saison → Ruhetage → Öffnungszeiten (OSM, nur Wochentage).
/// Ohne Ruhetage und ohne lesbare Öffnungszeiten ist das Ergebnis
/// [OpeningStatus.unknown].
OpeningStatus openingStatusOn(FoodPlace place, DateTime date) {
  if (place.isSeasonal &&
      !isInSeason(MonthDay.of(date), place.seasonFrom!, place.seasonTo!)) {
    return OpeningStatus.outOfSeason;
  }
  if (place.restDays.contains(date.weekday)) return OpeningStatus.restDay;

  final hours = place.openingHours;
  if (hours != null && hours.trim().isNotEmpty) {
    final openDays = parseOpenWeekdays(hours);
    if (openDays == null) return OpeningStatus.unknown;
    return openDays.contains(date.weekday)
        ? OpeningStatus.open
        : OpeningStatus.restDay;
  }

  return place.restDays.isEmpty ? OpeningStatus.unknown : OpeningStatus.open;
}

/// Saisonprüfung mit Jahreswechsel (z. B. 11-01 bis 02-28).
bool isInSeason(MonthDay day, MonthDay from, MonthDay to) {
  if (from <= to) return from <= day && day <= to;
  return from <= day || day <= to;
}

const Map<String, int> _osmDays = {
  'Mo': 1,
  'Tu': 2,
  'We': 3,
  'Th': 4,
  'Fr': 5,
  'Sa': 6,
  'Su': 7,
};

final RegExp _timeRange = RegExp(r'^\d{1,2}:\d{2}-\d{1,2}:\d{2}$');

/// Liest aus OSM-`opening_hours` die Wochentage, an denen geöffnet ist.
///
/// Unterstützt die häufige Teilmenge: `Mo-Fr 11:00-22:00; Sa,Su 10:00-23:00;
/// We off`, außerdem `24/7`. Feiertage (`PH`) werden ignoriert. Alles andere
/// (Monate, Wochen, Kommentare …) ergibt `null` = nicht sicher lesbar.
// ANNAHME: Für die Einkehr genügt „an diesem Tag geöffnet ja/nein“; Uhrzeiten
// werden erst mit dem Tagesablauf (M4) ausgewertet.
Set<int>? parseOpenWeekdays(String openingHours) {
  final text = openingHours.trim();
  if (text == '24/7') return {1, 2, 3, 4, 5, 6, 7};

  final open = <int>{};
  for (final rawRule in text.split(';')) {
    final rule = rawRule.trim();
    if (rule.isEmpty) continue;

    final parts = rule.split(RegExp(r'\s+'));
    final daySpec = parts.first;
    final rest = parts.skip(1).join(' ');

    final days = <int>{};
    for (final item in daySpec.split(',')) {
      if (item == 'PH') continue;
      final range = item.split('-');
      if (range.length == 1) {
        final d = _osmDays[range[0]];
        if (d == null) return null;
        days.add(d);
      } else if (range.length == 2) {
        final from = _osmDays[range[0]];
        final to = _osmDays[range[1]];
        if (from == null || to == null) return null;
        // Bereiche über das Wochenende hinweg, z. B. Fr-Mo.
        for (var d = from; ; d = d % 7 + 1) {
          days.add(d);
          if (d == to) break;
        }
      } else {
        return null;
      }
    }

    if (rest == 'off' || rest == 'closed') {
      open.removeAll(days);
    } else if (rest.split(',').every((t) => _timeRange.hasMatch(t.trim()))) {
      open.addAll(days);
    } else {
      return null;
    }
  }
  return open;
}
