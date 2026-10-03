import 'dart:async';

import 'package:wandern/features/navigation/data/location_source.dart';
import 'package:wandern/features/navigation/data/navigation_alerts.dart';
import 'package:wandern/features/navigation/domain/navigation_engine.dart';

/// Standortquelle, die der Test selbst füttert.
class FakeLocationSource implements LocationSource {
  final controller = StreamController<LocationFix>.broadcast();
  NavigationNotice? lastNotice;
  int watchCount = 0;

  @override
  Stream<LocationFix> watch(NavigationNotice notice) {
    lastNotice = notice;
    watchCount++;
    return controller.stream;
  }

  void emit(LocationFix fix) => controller.add(fix);
}

class FakePermissionService implements LocationPermissionService {
  FakePermissionService({
    this.current = LocationAccess.denied,
    this.onRequest = LocationAccess.granted,
  });

  LocationAccess current;
  LocationAccess onRequest;
  int requests = 0;

  @override
  Future<LocationAccess> check() async => current;

  @override
  Future<LocationAccess> request() async {
    requests++;
    return current = onRequest;
  }

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> openLocationSettings() async {}
}

class FakeAlerts implements NavigationAlerts {
  final spoken = <String>[];
  int vibrations = 0;

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async {}

  @override
  Future<void> vibrate() async => vibrations++;
}
