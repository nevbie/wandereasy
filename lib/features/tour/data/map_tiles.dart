import 'dart:typed_data';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../offline/data/offline_providers.dart';

/// Kachel-Cache, der ohne Netz auch veraltete Kacheln zeigt.
///
/// Online gelten unverändert die Cache-Angaben des Kachelservers. Offline
/// wäre eine Anfrage ohnehin erfolglos; statt einer leeren Karte wird dann
/// die zuletzt geladene Kachel gezeigt („stale-if-error“). Es entstehen
/// dadurch keine zusätzlichen Anfragen an den Server.
class OfflineTolerantCachingProvider implements MapCachingProvider {
  OfflineTolerantCachingProvider(this._inner, {required this.isOffline});

  final MapCachingProvider _inner;
  final bool Function() isOffline;

  static final DateTime _farFuture = DateTime.utc(9999);

  @override
  bool get isSupported => _inner.isSupported;

  @override
  Future<CachedMapTile?> getTile(String url) async {
    final tile = await _inner.getTile(url);
    if (tile == null || !tile.metadata.isStale || !isOffline()) return tile;
    return (
      bytes: tile.bytes,
      metadata: CachedMapTileMetadata(
        staleAt: _farFuture,
        lastModified: tile.metadata.lastModified,
        etag: tile.metadata.etag,
      ),
    );
  }

  @override
  Future<void> putTile({
    required String url,
    required CachedMapTileMetadata metadata,
    Uint8List? bytes,
  }) => _inner.putTile(url: url, metadata: metadata, bytes: bytes);
}

/// Hintergrundkarte laden? In Widget-Tests abgeschaltet (kein Netz).
final mapTilesEnabledProvider = Provider<bool>((ref) => true);

final mapCachingProvider = Provider<MapCachingProvider>(
  (ref) => OfflineTolerantCachingProvider(
    BuiltInMapCachingProvider.getOrCreateInstance(),
    isOffline: () => ref.read(isOnlineProvider).value == false,
  ),
);
