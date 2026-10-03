import '../domain/tour.dart';
import '../domain/tour_repository.dart';

/// Feste Tourenliste, z. B. für Tests.
class InMemoryTourRepository implements TourRepository {
  const InMemoryTourRepository(this.tours);

  final List<Tour> tours;

  @override
  Future<List<Tour>> allTours() async => tours;
}
