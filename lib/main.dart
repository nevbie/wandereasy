import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/settings/preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  if (!kIsWeb) {
    // Kachel-Cache im App-Verzeichnis statt im System-Cache, damit das
    // Betriebssystem angesehene Karten nicht vor der Wanderung wegräumt.
    final dir = await getApplicationSupportDirectory();
    BuiltInMapCachingProvider.getOrCreateInstance(
      cacheDirectory: '${dir.path}/map_tiles',
      maxCacheSize: 300 * 1000 * 1000,
    );
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const WanderApp(),
    ),
  );
}
