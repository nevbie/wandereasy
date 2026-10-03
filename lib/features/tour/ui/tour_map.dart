import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../core/config/app_config.dart';
import '../../../core/geo/lat_lng.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../offline/data/offline_providers.dart';
import '../data/map_tiles.dart';
import '../domain/tour.dart';
import '../domain/tour_places.dart';
import 'tour_icons.dart';

/// Farben der Kartensymbole (gut unterscheidbar, Kontrast zu Weiß).
abstract final class MapColors {
  static const Color route = Color(0xFF1B7F2A);
  static const Color food = Color(0xFFB34700);
  static const Color poi = Color(0xFF1F5A99);
  static const Color start = Color(0xFF1B7F2A);
  static const Color end = Color(0xFF7A1F1F);
}

ll.LatLng _ll(LatLng p) => ll.LatLng(p.lat, p.lng);

/// Karte im Tour-Detail (SPEC 5.4): Route, Start/Ziel, Einkehr, POIs.
/// Zoomen geht auch über die Knöpfe „+“ und „−“ (SPEC 4: nur Tippen).
class TourMap extends ConsumerStatefulWidget {
  const TourMap({super.key, required this.tour, this.height = 320});

  final Tour tour;
  final double height;

  @override
  ConsumerState<TourMap> createState() => _TourMapState();
}

class _TourMapState extends ConsumerState<TourMap> {
  final _controller = MapController();

  void _zoom(double delta) {
    final camera = _controller.camera;
    _controller.move(camera.center, camera.zoom + delta);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tour = widget.tour;
    if (tour.route.length < 2) return const SizedBox.shrink();

    final tilesEnabled = ref.watch(mapTilesEnabledProvider);
    final offline = ref.watch(isOnlineProvider).value == false;
    final route = [for (final p in tour.route) _ll(p)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: widget.height,
            child: Stack(
              children: [
                Semantics(
                  label: l10n.mapSemantics,
                  container: true,
                  child: ExcludeSemantics(
                    child: FlutterMap(
                      mapController: _controller,
                      options: MapOptions(
                        initialCameraFit: CameraFit.coordinates(
                          coordinates: route,
                          padding: const EdgeInsets.fromLTRB(40, 40, 80, 40),
                        ),
                        minZoom: 8,
                        maxZoom: 18,
                        backgroundColor: const Color(0xFFE8EDE4),
                        interactionOptions: const InteractionOptions(
                          // Kein Drehen – verwirrt mehr, als es hilft.
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
                      ),
                      children: [
                        if (tilesEnabled)
                          TileLayer(
                            urlTemplate: AppConfig.mapTileUrl,
                            userAgentPackageName: 'de.naturfreunde.wandern',
                            tileProvider: NetworkTileProvider(
                              cachingProvider: ref.watch(mapCachingProvider),
                            ),
                          ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: route,
                              color: MapColors.route,
                              strokeWidth: 6,
                              borderColor: Colors.white,
                              borderStrokeWidth: 2,
                            ),
                          ],
                        ),
                        MarkerLayer(markers: _markers(context, tour)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Column(
                    children: [
                      _MapButton(
                        label: '+',
                        semantics: l10n.mapZoomIn,
                        onPressed: () => _zoom(1),
                      ),
                      const SizedBox(height: AppSizes.tapTargetGap),
                      _MapButton(
                        label: '−',
                        semantics: l10n.mapZoomOut,
                        onPressed: () => _zoom(-1),
                      ),
                    ],
                  ),
                ),
                const Positioned(left: 0, bottom: 0, child: _Attribution()),
              ],
            ),
          ),
        ),
        if (offline) ...[
          const SizedBox(height: 8),
          Text(
            l10n.mapOfflineHint,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }

  List<Marker> _markers(BuildContext context, Tour tour) {
    final l10n = AppLocalizations.of(context);
    final markers = <Marker>[];

    for (final poi in tour.pois) {
      final at = poiLocation(tour, poi);
      if (at == null) continue;
      markers.add(
        Marker(
          point: _ll(at),
          width: 36,
          height: 36,
          child: _Dot(icon: poiIcon(poi.kind), color: MapColors.poi, size: 36),
        ),
      );
    }

    for (final food in tour.food) {
      final at = foodLocation(tour, food);
      if (at == null) continue;
      markers.add(
        Marker(
          point: _ll(at),
          width: 160,
          height: 80,
          alignment: Alignment.topCenter,
          child: _LabeledMarker(
            icon: foodIcon(food.place.kind),
            color: MapColors.food,
            label: food.place.name,
          ),
        ),
      );
    }

    if (startEqualsEnd(tour)) {
      markers.add(
        _flag(tour.route.first, Icons.flag, MapColors.start, l10n.mapStartEnd),
      );
    } else {
      markers
        ..add(
          _flag(tour.route.first, Icons.flag, MapColors.start, l10n.mapStart),
        )
        ..add(
          _flag(
            tour.route.last,
            Icons.sports_score,
            MapColors.end,
            l10n.mapEnd,
          ),
        );
    }
    return markers;
  }

  Marker _flag(LatLng at, IconData icon, Color color, String label) => Marker(
    point: _ll(at),
    width: 160,
    height: 80,
    alignment: Alignment.topCenter,
    child: _LabeledMarker(icon: icon, color: color, label: label),
  );
}

/// Rundes Symbol auf der Karte.
class _Dot extends StatelessWidget {
  const _Dot({required this.icon, required this.color, required this.size});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
    ),
    child: Icon(icon, color: Colors.white, size: size * 0.6),
  );
}

/// Symbol mit Beschriftung (Einkehr, Start, Ziel). Die Spitze zeigt auf
/// den Punkt; Beschriftung darüber.
class _LabeledMarker extends StatelessWidget {
  const _LabeledMarker({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    // Beschriftungen auf der Karte haben feste Größe; die volle
    // Information steht in den Listen unter der Karte.
    return MediaQuery.withNoTextScaling(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color, width: 2),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          _Dot(icon: icon, color: color, size: 40),
        ],
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.label,
    required this.semantics,
    required this.onPressed,
  });

  final String label;
  final String semantics;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: semantics,
      button: true,
      excludeSemantics: true,
      child: Material(
        color: scheme.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outline),
        ),
        child: InkWell(
          onTap: onPressed,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            width: AppSizes.minTapTarget,
            height: AppSizes.minTapTarget,
            child: Center(
              child: Text(
                label,
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Immer sichtbare Zuordnung (SPEC 9).
class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white.withValues(alpha: 0.9),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    child: const Text(
      AppConfig.mapAttribution,
      textScaler: TextScaler.noScaling,
      style: TextStyle(fontSize: 14, color: Colors.black),
    ),
  );
}
