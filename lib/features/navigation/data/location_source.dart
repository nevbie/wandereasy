import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/geo/lat_lng.dart';
import '../domain/navigation_engine.dart';
import '../domain/walk_simulator.dart';

/// Texte der dauerhaften Benachrichtigung während der Navigation.
class NavigationNotice {
  const NavigationNotice({required this.title, required this.text});

  final String title;
  final String text;
}

/// Quelle für Standorte. Der Standort wird nur auf dem Gerät verarbeitet
/// (SPEC 10) und nirgends gespeichert.
abstract interface class LocationSource {
  Stream<LocationFix> watch(NavigationNotice notice);
}

/// Echter Standort über GPS.
///
/// Android: Vordergrunddienst mit Benachrichtigung „Navigation läuft“,
/// damit der Bildschirm aus sein darf (SPEC 5.7). Akku-sparend: alle 5 s
/// bzw. 10 m.
class GeolocatorLocationSource implements LocationSource {
  const GeolocatorLocationSource();

  @override
  Stream<LocationFix> watch(NavigationNotice notice) {
    final LocationSettings settings;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      settings = AndroidSettings(
        distanceFilter: 10,
        intervalDuration: const Duration(seconds: 5),
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: notice.title,
          notificationText: notice.text,
          notificationChannelName: notice.title,
          setOngoing: true,
        ),
      );
    } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      settings = AppleSettings(
        distanceFilter: 10,
        activityType: ActivityType.fitness,
        showBackgroundLocationIndicator: true,
        pauseLocationUpdatesAutomatically: false,
      );
    } else {
      settings = const LocationSettings(distanceFilter: 10);
    }
    return Geolocator.getPositionStream(locationSettings: settings).map(
      (p) => LocationFix(
        LatLng(p.latitude, p.longitude),
        p.timestamp,
        accuracyM: p.accuracy,
      ),
    );
  }
}

/// Probelauf ohne GPS: läuft die Route im Zeitraffer ab, mit einem
/// Abstecher, damit die Abweichungswarnung vorgeführt werden kann.
class SimulatedLocationSource implements LocationSource {
  SimulatedLocationSource(
    this.route, {
    this.realInterval = const Duration(milliseconds: 500),
    this.speedMps = 1.2,
  });

  final List<LatLng> route;

  /// Echte Zeit zwischen zwei Standorten (simuliert sind es 5 s).
  final Duration realInterval;
  final double speedMps;

  @override
  Stream<LocationFix> watch(NavigationNotice notice) async* {
    final fixes = simulateWalk(
      route,
      start: DateTime.now(),
      speedMps: speedMps,
      detours: const [
        Detour(atM: 600, offsetM: 60, duration: Duration(seconds: 40)),
      ],
      jitterM: 5,
    );
    for (final fix in fixes) {
      await Future<void>.delayed(realInterval);
      yield fix;
    }
  }
}

enum LocationAccess { granted, denied, deniedForever, serviceDisabled }

/// Berechtigung erst bei Bedarf und nach Erklärung abfragen (SPEC 10).
abstract interface class LocationPermissionService {
  Future<LocationAccess> check();
  Future<LocationAccess> request();
  Future<void> openAppSettings();
  Future<void> openLocationSettings();
}

class GeolocatorPermissionService implements LocationPermissionService {
  const GeolocatorPermissionService();

  LocationAccess _map(LocationPermission p) => switch (p) {
    LocationPermission.always ||
    LocationPermission.whileInUse => LocationAccess.granted,
    LocationPermission.deniedForever => LocationAccess.deniedForever,
    _ => LocationAccess.denied,
  };

  @override
  Future<LocationAccess> check() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAccess.serviceDisabled;
    }
    return _map(await Geolocator.checkPermission());
  }

  @override
  Future<LocationAccess> request() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAccess.serviceDisabled;
    }
    return _map(await Geolocator.requestPermission());
  }

  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}
