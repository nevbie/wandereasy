import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandern/features/search/domain/search_criteria.dart';
import 'package:wandern/features/search/domain/tour_filter.dart';
import 'package:wandern/features/tour/data/demo_tour_repository.dart';
import 'package:wandern/features/tour/domain/start_point.dart';
import 'package:wandern/features/tour/domain/tour.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Tour> refs;

  setUpAll(() async {
    refs = await DemoTourRepository(
      rootBundle,
      indexAssets: const [DemoTourRepository.referenceIndex],
    ).allTours();
  });

  test('9 Referenz-Routen, sichtbar als Referenz gekennzeichnet', () {
    expect(refs, hasLength(9));
    for (final t in refs) {
      expect(t.isDemo, isFalse, reason: t.id);
      expect(t.sourceNote, contains('vor Veröffentlichung prüfen'));
      // Rundwege: Start = Ziel
      expect(t.route.length, greaterThan(100), reason: t.id);
      expect(withinLengthLimit(t), isTrue, reason: t.id);
      // Keine erfundenen Fahrzeiten
      expect(t.ride.toStartMin, isNull, reason: t.id);
      expect(t.ride.fromEndMin, isNull, reason: t.id);
    }
  });

  test('Werte aus den GPX-Dateien plausibel', () {
    Tour byId(String id) => refs.firstWhere((t) => t.id == id);
    final seelein = byId('ref_vhh_seelein_ravensburg');
    expect(seelein.distanceM / 1000, closeTo(11.4, 0.2));
    expect(seelein.ascentM, closeTo(173, 15));
    final bergtheim = byId('ref_bergtheim_harfenspiel');
    expect(bergtheim.distanceM / 1000, closeTo(6.6, 0.2));
    expect(bergtheim.difficulty, Difficulty.easy);
  });

  test('Veitshöchheim: Rundwege ab beiden Startpunkten, andere Orte mit '
      'Bus/Bahn hin und zurück', () {
    final loops = refs.where((t) => t.tourType == TourType.loop);
    expect(loops, hasLength(3));
    for (final t in loops) {
      expect(t.startPointIds, containsAll(StartPointIds.all));
    }
    final rides = refs.where((t) => t.tourType == TourType.rideBothWays);
    expect(rides, hasLength(6));
    for (final t in rides) {
      expect(t.stopA, isNotNull);
      expect(t.stopA!.id, t.stopB!.id); // Rundweg: A = B
    }
  });

  test('Suche „Rundweg“ ab Bahnhof findet die drei Veitshöchheimer Touren', () {
    final found = filterTours(
      refs,
      const SearchCriteria(
        startPointId: StartPointIds.bahnhof,
        tourType: TourType.loop,
      ),
    );
    expect(
      found.map((t) => t.id),
      unorderedEquals([
        'ref_vhh_seelein_ravensburg',
        'ref_vhh_schloss_seelein',
        'ref_vhh_mainufer_hofgarten',
      ]),
    );
    // Besonders schöne Landschaft zuerst
    expect(found.first.id, 'ref_vhh_seelein_ravensburg');
  });

  test('Touren mit unbekannter Fahrzeit bleiben auffindbar', () {
    final found = filterTours(
      refs,
      const SearchCriteria(
        startPointId: StartPointIds.bahnhof,
        tourType: TourType.rideBothWays,
      ),
    );
    expect(found, hasLength(6));
  });

  test('Einkehr am Mainufer mit unbekannten Öffnungszeiten', () {
    final t = refs.firstWhere((t) => t.id == 'ref_vhh_mainufer_hofgarten');
    expect(t.food.single.place.name, 'Meegärtle');
    expect(t.food.single.place.location, isNotNull);
    expect(t.food.single.place.openingHours, isNull);
  });
}
