import 'package:flutter/foundation.dart';

import '../../tour/domain/tour.dart';

/// Antwort auf „Wie lange möchten Sie gehen?“
enum DurationChoice {
  upTo2h,
  from2To4h,
  longer,
  any;

  bool matches(int durationMin) => switch (this) {
    upTo2h => durationMin <= 120,
    from2To4h => durationMin > 120 && durationMin <= 240,
    longer => durationMin > 240,
    any => true,
  };
}

/// Antwort auf „Wie anstrengend?“
enum EffortChoice {
  easy,
  medium,
  any;

  // ANNAHME: „mittel“ heißt „höchstens mittel“, schließt also leichte Touren
  // ein (siehe DECISIONS.md).
  bool matches(Difficulty d) => switch (this) {
    easy => d == Difficulty.easy,
    medium => d != Difficulty.hard,
    any => true,
  };
}

/// Antwort auf „Wie lange höchstens fahren (einfach)?“
enum RideChoice {
  upTo30,
  upTo60,
  upTo90,
  any;

  int? get maxMin => switch (this) {
    upTo30 => 30,
    upTo60 => 60,
    upTo90 => 90,
    any => null,
  };
}

/// Alle Antworten der Fragen-Suche (SPEC 5.2). `tourType == null` = „Egal“.
@immutable
class SearchCriteria {
  const SearchCriteria({
    required this.startPointId,
    this.tourType,
    this.duration = DurationChoice.any,
    this.effort = EffortChoice.any,
    this.requireFood = false,
    this.ride = RideChoice.any,
    this.date,
  });

  final String startPointId;
  final TourType? tourType;
  final DurationChoice duration;
  final EffortChoice effort;
  final bool requireFood;

  /// Nur bei `rideBothWays` gefragt.
  final RideChoice ride;

  /// Geplanter Tag; wenn gesetzt, zählt nur Einkehr, die dann geöffnet hat.
  final DateTime? date;

  /// Wird die Zusatzfrage zur Fahrzeit gestellt?
  bool get asksRideTime => tourType == TourType.rideBothWays;

  SearchCriteria copyWith({
    String? startPointId,
    TourType? Function()? tourType,
    DurationChoice? duration,
    EffortChoice? effort,
    bool? requireFood,
    RideChoice? ride,
    DateTime? Function()? date,
  }) => SearchCriteria(
    startPointId: startPointId ?? this.startPointId,
    tourType: tourType != null ? tourType() : this.tourType,
    duration: duration ?? this.duration,
    effort: effort ?? this.effort,
    requireFood: requireFood ?? this.requireFood,
    ride: ride ?? this.ride,
    date: date != null ? date() : this.date,
  );
}
