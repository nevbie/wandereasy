import 'package:drift/native.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandern/features/offline/data/app_database.dart';
import 'package:wandern/features/offline/data/saved_tours_repository.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('Tour-Detail zeigt Karte mit Zuordnung und Zoom-Knöpfen', (
    tester,
  ) async {
    await pumpApp(tester, initialLocation: '/tour/demo_walk_out');
    await tester.scrollUntilVisible(find.byType(FlutterMap), 200);

    expect(find.text('Karte'), findsOneWidget);
    expect(find.text('© OpenStreetMap-Mitwirkende'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Ziel'), findsOneWidget);
    expect(find.text('DEMO Häckerwirtschaft am Weinberg'), findsWidgets);

    final camera = MapCamera.of(tester.element(find.byType(PolylineLayer)));
    await tester.tap(find.bySemanticsLabel('Karte vergrößern'));
    await tester.pumpAndSettle();
    final zoomed = MapCamera.of(tester.element(find.byType(PolylineLayer)));
    expect(zoomed.zoom, closeTo(camera.zoom + 1, 0.01));
  });

  testWidgets('Speichern → Meine Touren → Löschen mit Bestätigung', (
    tester,
  ) async {
    await pumpApp(tester, initialLocation: '/tour/demo_loop');

    expect(find.textContaining('Benötigt ca.'), findsOneWidget);
    await tapVisible(tester, find.text('Für unterwegs speichern'));
    expect(find.text('Offline verfügbar'), findsOneWidget);
    expect(find.text('Für unterwegs speichern'), findsNothing);
    // Hinweis „Gespeichert …“ abwarten, er liegt über dem unteren Rand.
    expect(find.textContaining('Gespeichert.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.bySemanticsLabel('Meine Touren').last);
    expect(find.text('DEMO Rundweg Veitshöchheim'), findsOneWidget);
    expect(find.text('Wanderung starten'), findsOneWidget);

    await tapVisible(tester, find.text('Löschen'));
    expect(find.text('Tour löschen?'), findsOneWidget);
    await tapVisible(tester, find.text('Nein, zurück'));
    expect(find.text('DEMO Rundweg Veitshöchheim'), findsOneWidget);

    await tapVisible(tester, find.text('Löschen'));
    await tapVisible(tester, find.text('Ja, löschen'));
    expect(find.text('DEMO Rundweg Veitshöchheim'), findsNothing);
    expect(find.textContaining('noch keine Tour gespeichert'), findsOneWidget);
  });

  testWidgets('Flugmodus: gespeicherte Tour öffnet mit Karte (M2)', (
    tester,
  ) async {
    final tours = await loadDemoTours(tester);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(
      () =>
          SavedToursRepository(db)
              .save(tours.firstWhere((t) => t.id == 'demo_loop')),
    );

    await pumpApp(
      tester,
      initialLocation: '/meine-touren',
      online: false,
      database: db,
      tourRepository: OfflineTourRepository(),
    );

    expect(
      find.text('Kein Internet – gespeicherte Touren funktionieren trotzdem.'),
      findsOneWidget,
    );
    await tapVisible(tester, find.text('Tour ansehen'));

    expect(find.text('DEMO Rundweg Veitshöchheim'), findsOneWidget);
    await tester.scrollUntilVisible(find.byType(FlutterMap), 200);
    expect(find.byType(PolylineLayer), findsOneWidget);
    expect(find.text('Start und Ziel'), findsOneWidget);
    expect(
      find.textContaining('Ohne Internet zeigt die Karte'),
      findsOneWidget,
    );
  });
}
