import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../tour/domain/tour.dart';
import '../../tour/ui/tour_format.dart';
import '../domain/navigation_engine.dart';
import '../domain/route_matcher.dart';
import '../domain/tour_targets.dart';
import 'location_source.dart';
import 'navigation_alerts.dart';

final locationSourceProvider = Provider<LocationSource>(
  (ref) => const GeolocatorLocationSource(),
);

final locationPermissionProvider = Provider<LocationPermissionService>(
  (ref) => const GeolocatorPermissionService(),
);

final navigationAlertsProvider = Provider<NavigationAlerts>(
  (ref) => DeviceNavigationAlerts(),
);

/// Sprachansagen an/aus (Einstellung folgt in M7).
final voiceAnnouncementsProvider = Provider<bool>((ref) => true);

final navigationConfigProvider = Provider<NavigationConfig>(
  (ref) => const NavigationConfig(),
);

enum NavStatus {
  /// Erklärung vor der Berechtigungsabfrage.
  intro,
  denied,
  deniedForever,
  serviceDisabled,
  waitingForFix,
  running,
  paused,
  finished,
}

/// Hinweis-Banner unter der Restdistanz.
enum BannerKind { warning, info }

class NavBanner {
  const NavBanner(this.kind, this.text);

  final BannerKind kind;
  final String text;
}

class NavigationViewState {
  const NavigationViewState({
    this.status = NavStatus.intro,
    this.permissionGranted = false,
    this.simulated = false,
    this.engine,
    this.snapshot,
    this.banner,
  });

  final NavStatus status;

  /// Berechtigung liegt schon vor (anderer Knopftext).
  final bool permissionGranted;
  final bool simulated;
  final NavigationEngine? engine;
  final NavigationSnapshot? snapshot;
  final NavBanner? banner;

  NavigationViewState copyWith({
    NavStatus? status,
    bool? permissionGranted,
    bool? simulated,
    NavigationEngine? engine,
    NavigationSnapshot? snapshot,
    NavBanner? Function()? banner,
  }) => NavigationViewState(
    status: status ?? this.status,
    permissionGranted: permissionGranted ?? this.permissionGranted,
    simulated: simulated ?? this.simulated,
    engine: engine ?? this.engine,
    snapshot: snapshot ?? this.snapshot,
    banner: banner != null ? banner() : this.banner,
  );
}

/// Steuert eine laufende Navigation (SPEC 5.7). Eine Instanz je Tour; wird
/// beim Verlassen des Bildschirms beendet.
class NavigationController extends Notifier<NavigationViewState> {
  NavigationController(this.tourId);

  final String tourId;

  // Die App ist nur deutsch; Ansagen brauchen keinen BuildContext.
  final AppLocalizations _l10n = lookupAppLocalizations(const Locale('de'));

  StreamSubscription<LocationFix>? _sub;
  Timer? _ticker;
  LocationSource? _source;
  NavigationNotice? _notice;

  @override
  NavigationViewState build() {
    ref.onDispose(_stopTracking);
    unawaited(_checkPermission());
    return const NavigationViewState();
  }

  Future<void> _checkPermission() async {
    final access = await ref.read(locationPermissionProvider).check();
    if (!ref.mounted) return;
    if (state.status == NavStatus.intro) {
      state = state.copyWith(
        permissionGranted: access == LocationAccess.granted,
      );
    }
  }

  NavigationNotice _noticeFor(Tour tour) =>
      NavigationNotice(title: _l10n.navNoticeTitle, text: tour.name);

  /// Berechtigung erfragen (falls nötig) und mit echtem GPS starten.
  Future<void> start(Tour tour) async {
    final access = await ref.read(locationPermissionProvider).request();
    if (!ref.mounted) return;
    switch (access) {
      case LocationAccess.granted:
        _begin(tour, ref.read(locationSourceProvider), simulated: false);
      case LocationAccess.denied:
        state = state.copyWith(status: NavStatus.denied);
      case LocationAccess.deniedForever:
        state = state.copyWith(status: NavStatus.deniedForever);
      case LocationAccess.serviceDisabled:
        state = state.copyWith(status: NavStatus.serviceDisabled);
    }
  }

  /// Probelauf ohne GPS.
  void startSimulation(Tour tour) =>
      _begin(tour, SimulatedLocationSource(tour.route), simulated: true);

  void _begin(Tour tour, LocationSource source, {required bool simulated}) {
    final engine = NavigationEngine(
      route: tour.route,
      targets: tourTargets(tour, RouteMatcher(tour.route)),
      config: ref.read(navigationConfigProvider),
    );
    _source = source;
    _notice = _noticeFor(tour);
    state = NavigationViewState(
      status: NavStatus.waitingForFix,
      permissionGranted: true,
      simulated: simulated,
      engine: engine,
    );
    _startTracking();
  }

  void _startTracking() {
    _stopTracking();
    _sub = _source!.watch(_notice!).listen(_onFix, onError: (_) {});
    _ticker = Timer.periodic(const Duration(seconds: 5), (_) {
      final engine = state.engine;
      if (engine == null || state.simulated) return;
      _handle(engine.tick(DateTime.now()));
    });
  }

  void _stopTracking() {
    unawaited(_sub?.cancel());
    _sub = null;
    _ticker?.cancel();
    _ticker = null;
  }

  void _onFix(LocationFix fix) {
    final engine = state.engine;
    if (engine == null || state.status == NavStatus.paused) return;
    final events = engine.update(fix);
    state = state.copyWith(
      status: state.status == NavStatus.waitingForFix
          ? NavStatus.running
          : state.status,
      snapshot: engine.snapshot,
    );
    _handle(events);
  }

  void _handle(List<NavigationEvent> events) {
    if (events.isEmpty) return;
    final alerts = ref.read(navigationAlertsProvider);
    final voice = ref.read(voiceAnnouncementsProvider);
    for (final event in events) {
      switch (event) {
        case OffRouteEvent(:final distanceM):
          final m = roundMeters(distanceM);
          state = state.copyWith(
            snapshot: state.engine!.snapshot,
            banner: () => NavBanner(BannerKind.warning, _l10n.navOffRoute(m)),
          );
          unawaited(alerts.vibrate());
          if (voice) unawaited(alerts.speak(_l10n.navOffRouteSpeech(m)));
        case BackOnRouteEvent():
          state = state.copyWith(
            banner: () => NavBanner(BannerKind.info, _l10n.navBackOnRoute),
          );
          if (voice) unawaited(alerts.speak(_l10n.navBackOnRoute));
        case ApproachingFoodEvent(:final name, :final distanceM):
          final m = roundMeters(distanceM);
          state = state.copyWith(
            banner: () =>
                NavBanner(BannerKind.info, _l10n.navApproachingFood(m, name)),
          );
          if (voice) {
            unawaited(alerts.speak(_l10n.navApproachingFoodSpeech(m, name)));
          }
        case ArrivedEvent():
          state = state.copyWith(
            banner: () => NavBanner(BannerKind.info, _l10n.navArrived),
          );
          unawaited(alerts.vibrate());
          if (voice) unawaited(alerts.speak(_l10n.navArrived));
      }
    }
  }

  /// Pause: Standort wird nicht verfolgt (spart Akku), keine Warnungen.
  void pause() {
    if (state.status != NavStatus.running &&
        state.status != NavStatus.waitingForFix) {
      return;
    }
    _stopTracking();
    state = state.copyWith(status: NavStatus.paused, banner: () => null);
  }

  void resume() {
    if (state.status != NavStatus.paused) return;
    state = state.copyWith(
      status: state.snapshot == null
          ? NavStatus.waitingForFix
          : NavStatus.running,
    );
    _startTracking();
  }

  void finish() {
    _stopTracking();
    unawaited(ref.read(navigationAlertsProvider).stop());
    state = state.copyWith(status: NavStatus.finished);
  }

  /// Nach „Erneut versuchen“ wieder zur Erklärung.
  void backToIntro() => state = state.copyWith(status: NavStatus.intro);

  Future<void> openAppSettings() =>
      ref.read(locationPermissionProvider).openAppSettings();

  Future<void> openLocationSettings() =>
      ref.read(locationPermissionProvider).openLocationSettings();
}

final navigationControllerProvider = NotifierProvider.autoDispose
    .family<NavigationController, NavigationViewState, String>(
      NavigationController.new,
    );
