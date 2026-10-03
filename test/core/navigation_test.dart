import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    group('Schrift ${(scale * 100).round()} %', () {
      testWidgets('Startseite zeigt Begrüßung und drei große Knöpfe', (
        tester,
      ) async {
        await pumpApp(tester, textScale: scale);

        expect(find.text('Willkommen!'), findsOneWidget);
        expect(find.text('Wanderung suchen'), findsOneWidget);
        expect(find.text('Gruppenwanderungen'), findsOneWidget);
        // „Meine Touren“ als Knopf und in der unteren Leiste.
        expect(find.text('Meine Touren'), findsNWidgets(2));
        // Auf der Startseite gibt es kein „Zurück“.
        expect(find.text('Zurück'), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Untere Leiste hat genau vier Bereiche', (tester) async {
        await pumpApp(tester, textScale: scale);

        for (final label in [
          'Wanderungen',
          'Gruppen',
          'Meine Touren',
          'Hilfe',
        ]) {
          expect(find.bySemanticsLabel(label), findsWidgets, reason: label);
        }

        // Die Leiste darf den Inhalt nicht verdecken.
        final bar = tester.getRect(find.bySemanticsLabel('Hilfe').last);
        expect(bar.height, greaterThanOrEqualTo(56));
        expect(bar.top, greaterThan(phoneSize.height * 0.75));
      });

      testWidgets('Alle Bereiche sind über die Leiste erreichbar', (
        tester,
      ) async {
        await pumpApp(tester, textScale: scale);

        Future<void> tapBar(String label) async {
          await tester.tap(find.bySemanticsLabel(label).last);
          await tester.pumpAndSettle();
        }

        await tapBar('Gruppen');
        expect(find.text('Gruppenwanderungen'), findsOneWidget);
        expect(find.text('Willkommen!'), findsNothing);

        await tapBar('Meine Touren');
        expect(
          find.textContaining('noch keine Tour gespeichert'),
          findsOneWidget,
        );

        await tapBar('Hilfe');
        expect(find.text('Hilfe'), findsWidgets);

        await tapBar('Wanderungen');
        expect(find.text('Willkommen!'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Wanderung suchen → Zurück führt zur Startseite', (
        tester,
      ) async {
        await pumpApp(tester, textScale: scale);

        await tester.tap(find.text('Wanderung suchen'));
        await tester.pumpAndSettle();
        expect(find.text('Willkommen!'), findsNothing);
        expect(find.text('Zurück'), findsOneWidget);

        await tester.tap(find.text('Zurück'));
        await tester.pumpAndSettle();
        expect(find.text('Willkommen!'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('„Zur Startseite“ aus einem Bereich', (tester) async {
        await pumpApp(tester, textScale: scale, initialLocation: '/hilfe');

        await tester.ensureVisible(find.text('Zur Startseite'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Zur Startseite'));
        await tester.pumpAndSettle();
        expect(find.text('Willkommen!'), findsOneWidget);
      });
    });
  }

  testWidgets('Zurück-Knopf ist oben links', (tester) async {
    await pumpApp(tester, initialLocation: '/suche');
    final back = tester.getRect(find.text('Zurück'));
    expect(back.left, lessThan(phoneSize.width / 3));
    expect(back.top, lessThan(phoneSize.height / 5));
    expect(find.byType(Scaffold), findsWidgets);
  });
}
