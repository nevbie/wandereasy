import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'saved_tours_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final savedToursRepositoryProvider = Provider<SavedToursRepository>(
  (ref) => SavedToursRepository(ref.watch(appDatabaseProvider)),
);

final savedToursProvider = StreamProvider<List<SavedTour>>(
  (ref) => ref.watch(savedToursRepositoryProvider).watchAll(),
);

/// Ist die Tour für unterwegs gespeichert?
final isTourSavedProvider = Provider.family<bool, String>((ref, id) {
  final saved = ref.watch(savedToursProvider).value ?? const [];
  return saved.any((s) => s.tour.id == id);
});

/// `false`, wenn das Gerät keine Netzverbindung hat. Im Zweifel `true`,
/// damit nie fälschlich „Kein Internet“ erscheint.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  bool online(List<ConnectivityResult> r) =>
      r.any((c) => c != ConnectivityResult.none);
  try {
    yield online(await connectivity.checkConnectivity());
    yield* connectivity.onConnectivityChanged.map(online);
  } on Object {
    yield true;
  }
});
