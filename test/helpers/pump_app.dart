import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandern/app.dart';
import 'package:wandern/core/routing/app_router.dart';
import 'package:wandern/core/settings/preferences.dart';
import 'package:wandern/features/navigation/data/navigation_controller.dart';
import 'package:wandern/features/offline/data/app_database.dart';
import 'package:wandern/features/offline/data/offline_providers.dart';
import 'package:wandern/features/search/data/start_point_store.dart';
import 'package:wandern/features/tour/data/demo_tour_repository.dart';
import 'package:wandern/features/tour/data/in_memory_tour_repository.dart';
import 'package:wandern/features/tour/data/map_tiles.dart';
import 'package:wandern/features/tour/data/tour_providers.dart';
import 'package:wandern/features/tour/domain/start_point.dart';
import 'package:wandern/features/tour/domain/tour.dart';
import 'package:wandern/features/tour/domain/tour_repository.dart';

import 'navigation_fakes.dart';

/// Typische Telefongröße (logische Pixel).
const Size phoneSize = Size(360, 760);

/// Startet die ganze App in einer Telefongröße mit wählbarer Schriftgröße.
///
/// [startPoint]: bereits gewählter Startpunkt; `null` simuliert den
/// allerersten Start. [online]: `false` simuliert den Flugmodus.
/// [database]: z. B. eine Datenbank mit bereits gespeicherten Touren.
/// [tourRepository]: ersetzt die Demo-Touren.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  double textScale = 1.0,
  String initialLocation = '/',
  String? startPoint = StartPointIds.bahnhof,
  bool online = true,
  AppDatabase? database,
  TourRepository? tourRepository,
  FakeLocationSource? locationSource,
  FakePermissionService? permission,
  FakeAlerts? alerts,
}) async {
  tester.view
    ..physicalSize = phoneSize * tester.view.devicePixelRatio
    ..platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  SharedPreferences.setMockInitialValues({'start_point_id': ?startPoint});
  final prefs = await SharedPreferences.getInstance();

  final tours = await loadDemoTours(tester);
  final db = database ?? AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      tourRepositoryProvider.overrideWithValue(
        tourRepository ?? InMemoryTourRepository(tours),
      ),
      appDatabaseProvider.overrideWithValue(db),
      mapTilesEnabledProvider.overrideWithValue(false),
      isOnlineProvider.overrideWithValue(AsyncData(online)),
      locationSourceProvider.overrideWithValue(
        locationSource ?? FakeLocationSource(),
      ),
      locationPermissionProvider.overrideWithValue(
        permission ?? FakePermissionService(),
      ),
      navigationAlertsProvider.overrideWithValue(alerts ?? FakeAlerts()),
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

/// Lädt die Demo-Touren außerhalb der Fake-Async-Zone; sonst hängen
/// gecachte Futures von rootBundle in folgenden Tests.
Future<List<Tour>> loadDemoTours(WidgetTester tester) async =>
    (await tester.runAsync(() => DemoTourRepository(rootBundle).allTours()))!;

/// Tourenquelle, die wie ohne Internet immer fehlschlägt.
class OfflineTourRepository implements TourRepository {
  @override
  Future<List<Tour>> allTours() => Future.error(Exception('Kein Internet'));
}
