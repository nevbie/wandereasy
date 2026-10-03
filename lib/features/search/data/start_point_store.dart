import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/preferences.dart';
import '../../tour/domain/start_point.dart';

/// Gewählter Startpunkt, dauerhaft gespeichert. `null` = noch nicht gewählt
/// (dann erscheint beim ersten Start die Startpunkt-Wahl).
class StartPointNotifier extends Notifier<String?> {
  static const String _key = 'start_point_id';

  @override
  String? build() {
    final id = ref.watch(sharedPreferencesProvider).getString(_key);
    return StartPointIds.all.contains(id) ? id : null;
  }

  Future<void> select(String id) async {
    assert(StartPointIds.all.contains(id));
    state = id;
    await ref.read(sharedPreferencesProvider).setString(_key, id);
  }
}

final startPointProvider = NotifierProvider<StartPointNotifier, String?>(
  StartPointNotifier.new,
);
