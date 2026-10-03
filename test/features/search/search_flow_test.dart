import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandern/features/tour/data/tour_providers.dart';

import '../../helpers/pump_app.dart';

void main() {
  Future<void> next(WidgetTester tester) =>
      tapVisible(tester, find.text('Weiter'));

  testWidgets('Allererster Start: Startpunkt-Wahl, dann Startseite', (
    tester,
  ) async {
    await pumpApp(tester, startPoint: null);

    expect(find.text('Wo starten Sie?'), findsOneWidget);
    expect(find.text('Zurück'), findsNothing);

    await tapVisible(tester, find.text('Naturfreundehaus Veitshöchheim'));
    expect(find.text('Willkommen!'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('start_point_id'), 'nfh_vhh');
  });

  testWidgets('Suche Rundweg → Vorschlag → Detail mit Kurzfazit und Einkehr', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    // Montag: Demo-Gasthaus hat Ruhetag.
    container.read(plannedDateProvider.notifier).set(DateTime(2026, 10, 5));

    await tapVisible(tester, find.text('Wanderung suchen'));
    expect(find.text('Start: Bahnhof Veitshöchheim'), findsOneWidget);
    expect(find.text('Frage 1 von 4'), findsOneWidget);

    await tapVisible(
      tester,
      find.text('Rundweg ab Veitshöchheim – ohne Bus und Bahn'),
    );
    await next(tester);
    expect(find.text('Wie lange möchten Sie gehen?'), findsOneWidget);
    await next(tester);
    expect(find.text('Wie anstrengend?'), findsOneWidget);
    await next(tester);
    expect(find.text('Möchten Sie unterwegs einkehren?'), findsOneWidget);
    await tapVisible(tester, find.text('Ja, mit Einkehr'));
    await tapVisible(tester, find.text('Vorschläge zeigen'));

    expect(find.text('Vorschläge für Sie'), findsOneWidget);
    expect(find.text('DEMO Rundweg Veitshöchheim'), findsOneWidget);
    expect(find.text('DEMO Retzbach – Thüngersheim'), findsNothing);
    expect(find.text('Ohne Bus und Bahn'), findsOneWidget);

    await tapVisible(tester, find.text('DEMO Rundweg Veitshöchheim'));
    expect(
      find.text(
        '1 ¾ Std. · leicht · 5,5 km · 120 m bergauf · Einkehr unterwegs',
      ),
      findsOneWidget,
    );
    expect(find.text('Tagesablauf zeigen'), findsOneWidget);
    expect(find.text('Einkehren'), findsOneWidget);
    expect(find.text('DEMO Gasthaus Am Brunnen'), findsOneWidget);
    expect(find.text('Am Montag Ruhetag'), findsOneWidget);
    expect(find.text('Höhenprofil'), findsOneWidget);
  });

  testWidgets('Hin- und Rückfahrt fragt nach der Fahrzeit', (tester) async {
    await pumpApp(tester);
    await tapVisible(tester, find.text('Wanderung suchen'));
    await tapVisible(
      tester,
      find.text('Mit Bus/Bahn hin, wandern, mit Bus/Bahn zurück'),
    );
    expect(find.text('Frage 1 von 5'), findsOneWidget);
    await next(tester);
    await next(tester);
    await next(tester);
    await next(tester);
    expect(find.text('Wie lange höchstens fahren (einfach)?'), findsOneWidget);
    await tapVisible(tester, find.text('Bis 30 Minuten'));
    await tapVisible(tester, find.text('Vorschläge zeigen'));

    expect(find.text('DEMO Retzbach – Thüngersheim'), findsOneWidget);
    await tapVisible(tester, find.text('DEMO Retzbach – Thüngersheim'));
    expect(find.text('Verbindung zeigen'), findsOneWidget);
  });

  testWidgets('Keine Treffer: Fragen ändern', (tester) async {
    await pumpApp(tester);
    await tapVisible(tester, find.text('Wanderung suchen'));
    await tapVisible(
      tester,
      find.text('Rundweg ab Veitshöchheim – ohne Bus und Bahn'),
    );
    await next(tester);
    await tapVisible(tester, find.text('Länger als 4 Stunden'));
    await next(tester);
    await next(tester);
    await tapVisible(tester, find.text('Vorschläge zeigen'));

    expect(
      find.text('Keine passende Tour. Möchten Sie eine Frage ändern?'),
      findsOneWidget,
    );
    await tapVisible(tester, find.text('Fragen ändern'));
    expect(find.text('Wie möchten Sie wandern?'), findsOneWidget);
  });

  testWidgets('Startpunkt ändern aus der Suche', (tester) async {
    await pumpApp(tester);
    await tapVisible(tester, find.text('Wanderung suchen'));
    await tapVisible(tester, find.text('ändern'));
    expect(find.text('Wo starten Sie?'), findsOneWidget);

    await tapVisible(tester, find.text('Naturfreundehaus Veitshöchheim'));
    expect(find.text('Wie möchten Sie wandern?'), findsOneWidget);
    expect(find.text('Start: Naturfreundehaus Veitshöchheim'), findsOneWidget);
  });

  testWidgets('Alle Touren zeigen überspringt die Fragen', (tester) async {
    await pumpApp(tester);
    await tapVisible(tester, find.text('Wanderung suchen'));
    await tapVisible(tester, find.text('Alle Touren zeigen'));

    expect(find.text('Alle Touren'), findsOneWidget);
    for (final name in [
      'DEMO Rundweg Veitshöchheim',
      'DEMO Veitshöchheim – Thüngersheim',
      'DEMO Retzbach – Thüngersheim',
    ]) {
      await tester.scrollUntilVisible(find.text(name), 200);
      expect(find.text(name), findsOneWidget);
    }
  });
}
