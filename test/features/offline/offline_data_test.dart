import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandern/features/offline/data/app_database.dart';
import 'package:wandern/features/offline/data/saved_tours_repository.dart';
import 'package:wandern/features/tour/data/map_tiles.dart';
import 'package:wandern/features/tour/data/tour_codec.dart';
import 'package:wandern/features/tour/domain/tour.dart';

import '../../helpers/pump_app.dart';

class _FakeCache implements MapCachingProvider {
  _FakeCache(this.tile);

  final CachedMapTile? tile;

  @override
  bool get isSupported => true;

  @override
  Future<CachedMapTile?> getTile(String url) async => tile;

  @override
  Future<void> putTile({
    required String url,
    required CachedMapTileMetadata metadata,
    Uint8List? bytes,
  }) async {}
}

void main() {
  late List<Tour> demo;

  testWidgets('Demo-Touren laden', (tester) async {
    demo = await loadDemoTours(tester);
    expect(demo, hasLength(3));
  });

  test('TourCodec: Hin und zurück ergibt dieselben Daten', () {
    for (final t in demo) {
      final json = jsonEncode(TourCodec.toJson(t));
      final back = TourCodec.fromJson(jsonDecode(json) as Map<String, dynamic>);
      expect(jsonEncode(TourCodec.toJson(back)), json, reason: t.id);
      expect(back.route, t.route);
      expect(back.food.first.place.name, t.food.first.place.name);
      expect(back.food.first.place.seasonFrom, t.food.first.place.seasonFrom);
    }
  });

  test('Gespeicherte Touren: speichern, ersetzen, lesen, löschen', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SavedToursRepository(db);

    await repo.save(demo[0], now: DateTime(2026, 1, 1));
    await repo.save(demo[1], now: DateTime(2026, 1, 2));
    await repo.save(demo[0], now: DateTime(2026, 1, 3)); // erneut speichern

    final all = await repo.watchAll().first;
    expect(all.map((s) => s.tour.id), [demo[0].id, demo[1].id]);
    expect(
      all.first.sizeBytes,
      SavedToursRepository.estimateSizeBytes(demo[0]),
    );

    expect((await repo.get(demo[1].id))!.name, demo[1].name);
    await repo.delete(demo[1].id);
    expect(await repo.get(demo[1].id), isNull);
    expect(await repo.watchAll().first, hasLength(1));
  });

  group('Kachel-Cache ohne Netz', () {
    final staleTile = (
      bytes: Uint8List(1),
      metadata: CachedMapTileMetadata(
        staleAt: DateTime.utc(2000),
        lastModified: null,
        etag: 'e',
      ),
    );

    test('online: veraltete Kachel bleibt veraltet (Server fragen)', () async {
      final p = OfflineTolerantCachingProvider(
        _FakeCache(staleTile),
        isOffline: () => false,
      );
      expect((await p.getTile('u'))!.metadata.isStale, isTrue);
    });

    test('offline: veraltete Kachel wird trotzdem gezeigt', () async {
      final p = OfflineTolerantCachingProvider(
        _FakeCache(staleTile),
        isOffline: () => true,
      );
      final tile = (await p.getTile('u'))!;
      expect(tile.metadata.isStale, isFalse);
      expect(tile.metadata.etag, 'e');
    });

    test('ohne Kachel im Cache: nichts', () async {
      final p = OfflineTolerantCachingProvider(
        _FakeCache(null),
        isOffline: () => true,
      );
      expect(await p.getTile('u'), isNull);
    });
  });
}
