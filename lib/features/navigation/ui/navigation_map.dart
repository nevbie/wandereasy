import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../core/config/app_config.dart';
import '../../../core/geo/lat_lng.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../tour/data/map_tiles.dart';
import '../../tour/ui/tour_map.dart';
import '../domain/navigation_engine.dart';

ll.LatLng _ll(LatLng p) => ll.LatLng(p.lat, p.lng);

/// Karte während der Navigation: folgt dem Standort, Route grün, gegangener
/// Teil grau (SPEC 5.7).
class NavigationMap extends ConsumerStatefulWidget {
  const NavigationMap({
    super.key,
    required this.engine,
    required this.snapshot,
    this.height = 320,
  });

  final NavigationEngine engine;
  final NavigationSnapshot? snapshot;
  final double height;

  @override
  ConsumerState<NavigationMap> createState() => _NavigationMapState();
}

class _NavigationMapState extends ConsumerState<NavigationMap> {
  static const double _followZoom = 16;
  final _controller = MapController();
  bool _ready = false;

  @override
  void didUpdateWidget(NavigationMap old) {
    super.didUpdateWidget(old);
    final pos = widget.snapshot?.fix.position;
    if (_ready && pos != null && pos != old.snapshot?.fix.position) {
      _controller.move(_ll(pos), _controller.camera.zoom);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _zoom(double delta) {
    final camera = _controller.camera;
    _controller.move(camera.center, camera.zoom + delta);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final snap = widget.snapshot;
    final matcher = widget.engine.matcher;
    final walked = snap == null ? <LatLng>[] : matcher.walkedPath(snap.match);
    final remaining = snap == null
        ? matcher.route
        : matcher.remainingPath(snap.match);
    final center = snap?.fix.position ?? matcher.route.first;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            Semantics(
              label: l10n.navMapSemantics,
              container: true,
              child: ExcludeSemantics(
                child: FlutterMap(
                  mapController: _controller,
                  options: MapOptions(
                    initialCenter: _ll(center),
                    initialZoom: _followZoom,
                    minZoom: 8,
                    maxZoom: 18,
                    backgroundColor: const Color(0xFFE8EDE4),
                    onMapReady: () => _ready = true,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    if (ref.watch(mapTilesEnabledProvider))
                      TileLayer(
                        urlTemplate: AppConfig.mapTileUrl,
                        userAgentPackageName: 'de.naturfreunde.wandern',
                        tileProvider: NetworkTileProvider(
                          cachingProvider: ref.watch(mapCachingProvider),
                        ),
                      ),
                    PolylineLayer(
                      polylines: [
                        if (walked.length >= 2)
                          Polyline(
                            points: [for (final p in walked) _ll(p)],
                            color: const Color(0xFF8A8A8A),
                            strokeWidth: 6,
                            borderColor: Colors.white,
                            borderStrokeWidth: 2,
                          ),
                        Polyline(
                          points: [for (final p in remaining) _ll(p)],
                          color: MapColors.route,
                          strokeWidth: 7,
                          borderColor: Colors.white,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _ll(matcher.route.last),
                          width: 40,
                          height: 40,
                          child: const MapDot(
                            icon: Icons.sports_score,
                            color: MapColors.end,
                            size: 40,
                          ),
                        ),
                        if (snap != null)
                          Marker(
                            point: _ll(snap.fix.position),
                            width: 34,
                            height: 34,
                            child: const _Me(),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Column(
                children: [
                  MapZoomButton(
                    label: '+',
                    semantics: l10n.mapZoomIn,
                    onPressed: () => _zoom(1),
                  ),
                  const SizedBox(height: AppSizes.tapTargetGap),
                  MapZoomButton(
                    label: '−',
                    semantics: l10n.mapZoomOut,
                    onPressed: () => _zoom(-1),
                  ),
                ],
              ),
            ),
            const Positioned(left: 0, bottom: 0, child: MapAttribution()),
          ],
        ),
      ),
    );
  }
}

/// „Hier bin ich“: blauer Punkt mit weißem Rand.
class _Me extends StatelessWidget {
  const _Me();

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF1565C0),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 4),
      boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black38)],
    ),
  );
}
