import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandern/core/geo/lat_lng.dart';
import 'package:wandern/features/navigation/data/location_source.dart';
import 'package:wandern/features/navigation/domain/navigation_engine.dart';
import 'package:wandern/features/navigation/domain/walk_simulator.dart';
import 'package:wandern/features/tour/domain/tour.dart';

import '../../helpers/navigation_fakes.dart';
import '../../helpers/pump_app.dart';

void main() {
  final t0 = DateTime(2026, 10, 3, 10);
  const location = '/meine-touren/navigation/demo_walk_out';

  Future<List<Tour>> tours(WidgetTester tester) => loadDemoTours(tester);

  testWidgets('Erklärung vor der Berechtigung, dann Standort gesucht', (
    tester,
  ) async {
    final permission = FakePermissionService();
    final source = FakeLocationSource();
    await pumpApp(
      tester,
      initialLocation: location,
      permission: permission,
      locationSource: source,
    );

    expect(
      find.textContaining('braucht die App Ihren Standort'),
      findsOneWidget,
    );
    expect(permission.requests, 0, reason: 'erst nach Erklärung fragen');

    await tapVisible(tester, find.text('Standort freigeben und starten'));
    expect(permission.requests, 1);
    expect(source.lastNotice!.title, 'Navigation läuft');
    expect(find.textContaining('Standort wird gesucht'), findsOneWidget);
    // Während der Navigation kein „Zurück“, nur „Wanderung beenden“.
    expect(find.text('Zurück'), findsNothing);
    expect(find.text('Wanderung beenden'), findsOneWidget);

    await tapVisible(tester, find.text('Wanderung beenden'));
    await tapVisible(tester, find.text('Ja, beenden'));
  });

  testWidgets('Standort verweigert: Hinweis, was zu tun ist', (tester) async {
    await pumpApp(
      tester,
      initialLocation: location,
      permission: FakePermissionService(onRequest: LocationAccess.denied),
    );
    await tapVisible(tester, find.text('Standort freigeben und starten'));
    expect(find.textContaining('Ohne Standort kann die App'), findsOneWidget);
    expect(find.text('Erneut versuchen'), findsOneWidget);
  });

  testWidgets('Simulierter Track: Restdistanz, Warnung mit Vibration und '
      'Sprache, wieder auf dem Weg, Ziel', (tester) async {
    final route = (await tours(tester))
        .firstWhere((t) => t.id == 'demo_walk_out')
        .route;
    final source = FakeLocationSource();
    final alerts = FakeAlerts();
    await pumpApp(
      tester,
      initialLocation: location,
      permission: FakePermissionService(current: LocationAccess.granted),
      locationSource: source,
      alerts: alerts,
    );
    expect(find.text('Navigation starten'), findsOneWidget);
    await tapVisible(tester, find.text('Navigation starten'));

    final fixes = simulateWalk(
      route,
      start: t0,
      detours: const [
        Detour(atM: 1500, offsetM: 60, duration: Duration(seconds: 40)),
      ],
    );
    Future<void> feed(Iterable<LocationFix> fs) async {
      for (final f in fs) {
        source.emit(f);
        await tester.pump();
      }
    }

    // Bis kurz nach Beginn des Abstechers
    final detourIdx = fixes.indexWhere(
      (f) => f.time.isAfter(t0.add(const Duration(minutes: 22))),
    );
    await feed(fixes.take(5));
    expect(find.textContaining('bis zum Ziel'), findsOneWidget);
    expect(find.textContaining('Noch '), findsWidgets);

    // Abstecher: 60 m für 40 s
    final offStart = fixes.indexWhere((f) {
      final i = fixes.indexOf(f);
      return i > 0 &&
          (f.position.lat - fixes[i - 1].position.lat).abs() +
                  (f.position.lng - fixes[i - 1].position.lng).abs() >
              0.0005;
    });
    expect(offStart, greaterThan(0));
    expect(detourIdx, greaterThan(0));
    await feed(fixes.sublist(5, offStart + 6)); // 25 s abseits
    expect(
      find.text('Sie sind vom Weg abgekommen. Bitte etwa 60 m zurückgehen.'),
      findsOneWidget,
    );
    expect(alerts.vibrations, 1);
    expect(
      alerts.spoken.last,
      'Sie sind vom Weg abgekommen. Bitte etwa 60 Meter zurückgehen.',
    );

    await feed(fixes.sublist(offStart + 6, offStart + 12));
    expect(alerts.spoken.last, 'Sie sind wieder auf dem Weg.');
    expect(find.textContaining('vom Weg abgekommen'), findsNothing);

    await feed(fixes.sublist(offStart + 12));
    // Ankündigung knapp 300 m vorher (Schrittweite des Tracks 5,5 m).
    expect(
      alerts.spoken,
      contains(matches(RegExp(r'^In (290|300) Metern: DEMO Café am Main$'))),
    );
    expect(alerts.spoken.last, 'Sie haben das Ziel erreicht.');
    expect(find.text('Sie haben das Ziel erreicht.'), findsOneWidget);

    // Beenden mit Bestätigung
    await tapVisible(tester, find.text('Wanderung beenden'));
    expect(find.text('Wanderung beenden?'), findsOneWidget);
    await tapVisible(tester, find.text('Ja, beenden'));
    expect(find.text('Meine Touren'), findsWidgets);
  });

  testWidgets('Pause: keine Verfolgung, Weiter wandern setzt fort', (
    tester,
  ) async {
    final source = FakeLocationSource();
    await pumpApp(
      tester,
      initialLocation: location,
      permission: FakePermissionService(current: LocationAccess.granted),
      locationSource: source,
    );
    await tapVisible(tester, find.text('Navigation starten'));
    source.emit(LocationFix(const LatLng(49.83, 9.882), t0));
    await tester.pump();

    await tapVisible(tester, find.text('Pause'));
    expect(find.textContaining('Pause – Ihr Standort'), findsOneWidget);
    expect(source.controller.hasListener, isFalse);

    await tapVisible(tester, find.text('Weiter wandern'));
    expect(source.controller.hasListener, isTrue);
    expect(source.watchCount, 2);

    // Navigation vor Testende beenden (Timer).
    await tapVisible(tester, find.text('Wanderung beenden'));
    await tapVisible(tester, find.text('Ja, beenden'));
  });

  testWidgets('Abkürzen öffnet den Abkürzen-Bildschirm', (tester) async {
    final source = FakeLocationSource();
    await pumpApp(
      tester,
      initialLocation: location,
      permission: FakePermissionService(current: LocationAccess.granted),
      locationSource: source,
    );
    await tapVisible(tester, find.text('Navigation starten'));
    await tapVisible(tester, find.text('Ich möchte abkürzen'));
    expect(find.text('Abkürzen'), findsOneWidget);
    await tapVisible(tester, find.text('Zurück'));
    expect(find.text('Ich möchte abkürzen'), findsOneWidget);
    await tapVisible(tester, find.text('Wanderung beenden'));
    await tapVisible(tester, find.text('Ja, beenden'));
    expect(find.byType(Scaffold), findsWidgets);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('Laufende Navigation mit Warnung: Barrierefreiheit bei '
        '${scale}x Schrift', (tester) async {
      final handle = tester.ensureSemantics();
      final source = FakeLocationSource();
      await pumpApp(
        tester,
        textScale: scale,
        initialLocation: location,
        permission: FakePermissionService(current: LocationAccess.granted),
        locationSource: source,
      );
      await tapVisible(tester, find.text('Navigation starten'));
      // 80 m neben dem Start, 25 s lang
      for (var s = 0; s <= 25; s += 5) {
        source.emit(
          LocationFix(
            const LatLng(49.8300, 9.8831),
            t0.add(Duration(seconds: s)),
          ),
        );
        await tester.pump();
      }
      expect(find.textContaining('vom Weg abgekommen'), findsOneWidget);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      expect(tester.takeException(), isNull);

      await tapVisible(tester, find.text('Wanderung beenden'));
      await tapVisible(tester, find.text('Ja, beenden'));
      handle.dispose();
    });
  }
}
