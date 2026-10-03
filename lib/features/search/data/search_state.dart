import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../tour/data/tour_providers.dart';
import '../../tour/domain/start_point.dart';
import '../../tour/domain/tour.dart';
import '../domain/search_criteria.dart';
import '../domain/tour_filter.dart';
import 'start_point_store.dart';

/// Antworten der laufenden Suche (ohne Startpunkt, der kommt separat).
class SearchAnswersNotifier extends Notifier<SearchCriteria> {
  @override
  SearchCriteria build() =>
      const SearchCriteria(startPointId: StartPointIds.bahnhof);

  void reset() => state = build();

  void setTourType(TourType? type) =>
      state = state.copyWith(tourType: () => type);

  void setDuration(DurationChoice v) => state = state.copyWith(duration: v);

  void setEffort(EffortChoice v) => state = state.copyWith(effort: v);

  void setRequireFood(bool v) => state = state.copyWith(requireFood: v);

  void setRide(RideChoice v) => state = state.copyWith(ride: v);
}

final searchAnswersProvider =
    NotifierProvider<SearchAnswersNotifier, SearchCriteria>(
      SearchAnswersNotifier.new,
    );

/// Vollständige Suchkriterien inkl. gewähltem Startpunkt.
final searchCriteriaProvider = Provider<SearchCriteria>((ref) {
  final answers = ref.watch(searchAnswersProvider);
  final start = ref.watch(startPointProvider) ?? StartPointIds.bahnhof;
  return answers.copyWith(startPointId: start);
});

/// Höchstens so viele Vorschläge (SPEC 5.3: 3–5).
const int maxSuggestions = 5;

final suggestionsProvider = FutureProvider<List<Tour>>((ref) async {
  final tours = await ref.watch(allToursProvider.future);
  final criteria = ref.watch(searchCriteriaProvider);
  return filterTours(tours, criteria).take(maxSuggestions).toList();
});

/// „Alle Touren zeigen“: alle Touren, die zum Startpunkt passen.
final allToursForStartProvider = FutureProvider<List<Tour>>((ref) async {
  final tours = await ref.watch(allToursProvider.future);
  final start = ref.watch(startPointProvider) ?? StartPointIds.bahnhof;
  return filterTours(tours, SearchCriteria(startPointId: start));
});
