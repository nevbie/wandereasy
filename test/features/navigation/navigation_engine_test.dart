import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandern/core/geo/lat_lng.dart';
import 'package:wandern/features/navigation/domain/navigation_engine.dart';
import 'package:wandern/features/navigation/domain/walk_simulator.dart';
import 'package:wandern/features/tour/data/demo_tour_repository.dart';
import 'package:wandern/features/tour/domain/tour.dart';

/// Spielt einen Track ab und sammelt alle Ereignisse mit Zeitpunkt.
List<(DateTime, NavigationEvent)> run(
  NavigationEngine engine,
  List<LocationFix> fixes,
) => [
  for (final f in fixes)
    for (final e in engine.update(f)) (f.time, e),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final t0 = DateTime(2026, 10, 3, 10);
  late List<Tour> tours;

  setUpAll(() async {
    tours = await DemoTourRepository(
      rootBundle,
      indexAssets: const [DemoTourRepository.demoIndex],
    ).allTours();
  });

  Tour tour(String id) => tours.firstWhere((t) => t.id == id);

  List<Type> types(List<(DateTime, NavigationEvent)> events) => [
    for (final (_, e) in events) e.runtimeType,
  ];

  group('Simulierter GPS-Track (Abnahme M3)', () {
    for (final id in ['demo_loop', 'demo_walk_out', 'demo_ride_both']) {
      test('$id: sauber gelaufen → keine Warnung, Ziel erreicht', () {
        final route = tour(id).route;
        final engine = NavigationEngine(route: route);
        final events = run(engine, simulateWalk(route, start: t0, jitterM: 10));
        expect(types(events), [ArrivedEvent]);
        expect(engine.snapshot!.remainingM, lessThan(40));
      });
    }

    test(
      '60 m abseits für 40 s → genau eine Warnung, dann wieder auf dem Weg',
      () {
        final route = tour('demo_walk_out').route;
        final engine = NavigationEngine(route: route);
        final fixes = simulateWalk(
          route,
          start: t0,
          detours: const [
            Detour(atM: 2000, offsetM: 60, duration: Duration(seconds: 40)),
          ],
        );
        final events = run(engine, fixes);
        expect(types(events), [OffRouteEvent, BackOnRouteEvent, ArrivedEvent]);

        final (warnAt, warn) = events.first;
        expect((warn as OffRouteEvent).distanceM, closeTo(60, 5));
        // Erster Standort > 40 m neben der Route, unabhängig ermittelt.
        final firstOff = fixes.firstWhere(
          (f) => engine.matcher.match(f.position).distanceToRouteM > 40,
        );
        expect(warnAt.difference(firstOff.time), const Duration(seconds: 20));
      },
    );

    test('nur 15 s abseits → keine Warnung', () {
      final route = tour('demo_walk_out').route;
      final events = run(
        NavigationEngine(route: route),
        simulateWalk(
          route,
          start: t0,
          detours: const [
            Detour(atM: 2000, offsetM: 60, duration: Duration(seconds: 15)),
          ],
        ),
      );
      expect(types(events), [ArrivedEvent]);
    });

    test('nur 30 m abseits → keine Warnung', () {
      final route = tour('demo_walk_out').route;
      final events = run(
        NavigationEngine(route: route),
        simulateWalk(
          route,
          start: t0,
          detours: const [
            Detour(atM: 2000, offsetM: 30, duration: Duration(minutes: 2)),
          ],
        ),
      );
      expect(types(events), [ArrivedEvent]);
    });

    test('lange abseits → Warnung wird jede Minute wiederholt', () {
      final route = tour('demo_walk_out').route;
      final events = run(
        NavigationEngine(route: route),
        simulateWalk(
          route,
          start: t0,
          detours: const [
            Detour(atM: 2000, offsetM: 80, duration: Duration(seconds: 150)),
          ],
        ),
      );
      final warnings = events.map((e) => e.$2).whereType<OffRouteEvent>();
      expect(warnings.map((w) => w.repeated), [false, true, true]);
    });
  });

  test('Stillstand abseits: Zeit läuft per tick weiter', () {
    const route = [LatLng(49.80, 9.80), LatLng(49.81, 9.80)];
    final engine = NavigationEngine(route: route);
    const off = LatLng(49.805, 9.801); // ≈ 72 m östlich
    expect(engine.update(LocationFix(off, t0)), isEmpty);
    expect(engine.tick(t0.add(const Duration(seconds: 19))), isEmpty);
    final events = engine.tick(t0.add(const Duration(seconds: 20)));
    expect(events.single, isA<OffRouteEvent>());
    expect(engine.snapshot!.offRoute, isTrue);
  });

  test('ungenauer Standort löst keine Warnung aus', () {
    const route = [LatLng(49.80, 9.80), LatLng(49.81, 9.80)];
    final engine = NavigationEngine(route: route);
    const off = LatLng(49.805, 9.801);
    for (var s = 0; s <= 60; s += 5) {
      final e = engine.update(
        LocationFix(off, t0.add(Duration(seconds: s)), accuracyM: 80),
      );
      expect(e, isEmpty);
    }
  });

  test('Einkehr wird bei 300 m einmal angekündigt, Restdistanzen', () {
    final t = tour('demo_loop'); // Gasthaus bei km 3
    final engine = NavigationEngine(
      route: t.route,
      targets: const [
        RouteTarget(name: 'Bank', kind: TargetKind.poi, alongM: 1500),
        RouteTarget(name: 'Gasthaus', kind: TargetKind.food, alongM: 3000),
      ],
    );
    final events = run(engine, simulateWalk(t.route, start: t0));
    final food = events.map((e) => e.$2).whereType<ApproachingFoodEvent>();
    expect(food, hasLength(1));
    expect(food.single.name, 'Gasthaus');
    expect(food.single.distanceM, inInclusiveRange(290, 300));
  });

  test('Momentaufnahme: nächstes Ziel und Restdistanz', () {
    const route = [LatLng(49.80, 9.80), LatLng(49.82, 9.80)]; // ≈ 2224 m
    final engine = NavigationEngine(
      route: route,
      targets: const [
        RouteTarget(name: 'Bank', kind: TargetKind.poi, alongM: 1000),
      ],
    );
    engine.update(LocationFix(const LatLng(49.801, 9.80), t0));
    final s = engine.snapshot!;
    expect(s.remainingM, closeTo(2224 - 111, 3));
    expect(s.nextTarget!.name, 'Bank');
    expect(s.nextTargetDistanceM, closeTo(1000 - 111, 3));
  });
}
