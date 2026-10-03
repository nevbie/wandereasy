import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandern/app.dart';
import 'package:wandern/core/routing/app_router.dart';
import 'package:wandern/core/settings/preferences.dart';
import 'package:wandern/features/search/data/start_point_store.dart';
import 'package:wandern/features/tour/data/demo_tour_repository.dart';
import 'package:wandern/features/tour/data/in_memory_tour_repository.dart';
import 'package:wandern/features/tour/data/tour_providers.dart';
import 'package:wandern/features/tour/domain/start_point.dart';

/// Typische Telefongröße (logische Pixel).
const Size phoneSize = Size(360, 760);

/// Startet die ganze App in einer Telefongröße mit wählbarer Schriftgröße.
///
/// [startPoint]: bereits gewählter Startpunkt; `null` simuliert den
/// allerersten Start.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  double textScale = 1.0,
  String initialLocation = '/',
  String? startPoint = StartPointIds.bahnhof,
}) async {
  tester.view
    ..physicalSize = phoneSize * tester.view.devicePixelRatio
    ..platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  SharedPreferences.setMockInitialValues({'start_point_id': ?startPoint});
  final prefs = await SharedPreferences.getInstance();

  // Assets außerhalb der Fake-Async-Zone laden; sonst hängen gecachte
  // Futures von rootBundle in folgenden Tests.
  final tours = await tester.runAsync(
    () => DemoTourRepository(rootBundle).allTours(),
  );

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      tourRepositoryProvider.overrideWithValue(InMemoryTourRepository(tours!)),
      appRouterProvider.overrideWith(
        (ref) => createAppRouter(
          initialLocation: initialLocation,
          needsStartPoint: () => ref.read(startPointProvider) == null,
        ),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const WanderApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Scrollt zu [finder] und tippt darauf.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
