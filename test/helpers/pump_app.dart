import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandern/app.dart';
import 'package:wandern/core/routing/app_router.dart';

/// Typische Telefongröße (logische Pixel).
const Size phoneSize = Size(360, 760);

/// Startet die ganze App in einer Telefongröße mit wählbarer Schriftgröße.
Future<void> pumpApp(
  WidgetTester tester, {
  double textScale = 1.0,
  String initialLocation = '/',
}) async {
  tester.view
    ..physicalSize = phoneSize * tester.view.devicePixelRatio
    ..platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appRouterProvider.overrideWithValue(
          createAppRouter(initialLocation: initialLocation),
        ),
      ],
      child: const WanderApp(),
    ),
  );
  await tester.pumpAndSettle();
}
