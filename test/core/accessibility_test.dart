import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  const locations = ['/', '/suche', '/gruppen', '/meine-touren', '/hilfe'];

  for (final location in locations) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Barrierefreiheit $location bei ${scale}x Schrift', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await pumpApp(tester, textScale: scale, initialLocation: location);

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        expect(tester.takeException(), isNull);
        handle.dispose();
      });
    }
  }
}
