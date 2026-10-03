import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/tour.dart';
import '../domain/tour_repository.dart';
import 'demo_tour_repository.dart';

final tourRepositoryProvider = Provider<TourRepository>(
  (ref) => DemoTourRepository(rootBundle),
);

final allToursProvider = FutureProvider<List<Tour>>(
  (ref) => ref.watch(tourRepositoryProvider).allTours(),
);

final tourByIdProvider = FutureProvider.family<Tour?, String>((ref, id) async {
  final tours = await ref.watch(allToursProvider.future);
  for (final t in tours) {
    if (t.id == id) return t;
  }
  return null;
});

/// Geplanter Wandertag. Standard: heute.
// ANNAHME: Bis zum Tagesablauf (M4) wählt man den Tag im Einkehr-Block;
// SPEC 5.5 nennt „heute/nächster Samstag“, wir nehmen heute.
class PlannedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void set(DateTime date) => state = DateTime(date.year, date.month, date.day);
}

final plannedDateProvider = NotifierProvider<PlannedDateNotifier, DateTime>(
  PlannedDateNotifier.new,
);
