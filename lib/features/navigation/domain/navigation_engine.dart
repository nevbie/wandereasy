import 'dart:math' as math;

import '../../../core/geo/lat_lng.dart';
import 'route_matcher.dart';

/// Eine Standortmeldung.
class LocationFix {
  const LocationFix(this.position, this.time, {this.accuracyM});

  final LatLng position;
  final DateTime time;

  /// Genauigkeit in Metern (68 %), falls bekannt.
  final double? accuracyM;
}

/// Grenzwerte der Navigation (SPEC 5.7: „Werte konfigurierbar“).
class NavigationConfig {
  const NavigationConfig({
    this.offRouteDistanceM = 40,
    this.offRouteDuration = const Duration(seconds: 20),
    this.backOnRouteDistanceM = 30,
    this.repeatWarningAfter = const Duration(seconds: 60),
    this.maxAccuracyM = 50,
    this.announceFoodWithinM = 300,
    this.arrivalWithinM = 40,
  });

  /// Ab dieser Entfernung zur Route gilt man als abgewichen …
  final double offRouteDistanceM;

  /// … wenn es mindestens so lange anhält.
  final Duration offRouteDuration;

  /// Wieder „auf dem Weg“ erst unterhalb dieser Entfernung (Hysterese,
  /// damit es an der Grenze nicht ständig hin- und herspringt).
  final double backOnRouteDistanceM;

  /// Warnung wiederholen, solange man abseits bleibt.
  final Duration repeatWarningAfter;

  /// Ungenauere Standorte lösen keine Warnung aus (z. B. im Wald).
  final double maxAccuracyM;

  /// „In 300 m: Gasthaus X“ (SPEC 5.11).
  final double announceFoodWithinM;

  /// So nah am Ende der Route gilt das Ziel als erreicht.
  final double arrivalWithinM;
}

enum TargetKind { food, poi }

/// Ein Ziel unterwegs (Einkehr oder POI) mit Lage auf der Route.
class RouteTarget {
  const RouteTarget({
    required this.name,
    required this.kind,
    required this.alongM,
  });

  final String name;
  final TargetKind kind;
  final double alongM;
}

/// Ereignisse, auf die Vibration, Sprache oder Banner reagieren.
sealed class NavigationEvent {
  const NavigationEvent();
}

class OffRouteEvent extends NavigationEvent {
  const OffRouteEvent(this.distanceM, {this.repeated = false});

  final double distanceM;
  final bool repeated;
}

class BackOnRouteEvent extends NavigationEvent {
  const BackOnRouteEvent();
}

class ApproachingFoodEvent extends NavigationEvent {
  const ApproachingFoodEvent(this.name, this.distanceM);

  final String name;
  final double distanceM;
}

class ArrivedEvent extends NavigationEvent {
  const ArrivedEvent();
}

/// Momentaufnahme für die Anzeige.
class NavigationSnapshot {
  const NavigationSnapshot({
    required this.fix,
    required this.match,
    required this.remainingM,
    required this.nextTarget,
    required this.nextTargetDistanceM,
    required this.offRoute,
    required this.arrived,
  });

  final LocationFix fix;
  final RouteMatch match;
  final double remainingM;
  final RouteTarget? nextTarget;
  final double? nextTargetDistanceM;

  /// Abweichungswarnung aktiv.
  final bool offRoute;
  final bool arrived;
}

/// Navigationslogik ohne Plattformabhängigkeiten (SPEC 5.7).
///
/// [update] verarbeitet neue Standorte, [tick] lässt die Zeit weiterlaufen,
/// wenn keine neuen Standorte kommen (z. B. Stillstand bei 10-m-Filter).
class NavigationEngine {
  NavigationEngine({
    required List<LatLng> route,
    List<RouteTarget> targets = const [],
    this.config = const NavigationConfig(),
  }) : matcher = RouteMatcher(route),
       targets = [...targets]..sort((a, b) => a.alongM.compareTo(b.alongM));

  final RouteMatcher matcher;
  final List<RouteTarget> targets;
  final NavigationConfig config;

  NavigationSnapshot? _snapshot;
  DateTime? _offSince;
  DateTime? _lastWarning;
  bool _warningActive = false;
  bool _arrived = false;
  final Set<RouteTarget> _announced = {};

  NavigationSnapshot? get snapshot => _snapshot;

  List<NavigationEvent> update(LocationFix fix) {
    final events = <NavigationEvent>[];
    final match = matcher.match(
      fix.position,
      nearAlongM: _snapshot?.match.alongM,
    );
    final reliable =
        fix.accuracyM == null || fix.accuracyM! <= config.maxAccuracyM;
    final dist = match.distanceToRouteM;

    if (dist <= config.backOnRouteDistanceM) {
      if (_warningActive) events.add(const BackOnRouteEvent());
      _offSince = null;
      _warningActive = false;
      _lastWarning = null;
    } else if (dist > config.offRouteDistanceM && reliable) {
      _offSince ??= fix.time;
    } else if (!_warningActive) {
      // Zwischen den Grenzen oder ungenau: Zeitmessung neu beginnen.
      _offSince = null;
    }

    final onRoute = !_warningActive && _offSince == null;
    if (onRoute) {
      for (final t in targets) {
        if (_announced.contains(t)) continue;
        final ahead = t.alongM - match.alongM;
        if (ahead < 0) {
          _announced.add(t); // schon vorbei
        } else if (t.kind == TargetKind.food &&
            ahead <= config.announceFoodWithinM) {
          _announced.add(t);
          events.add(ApproachingFoodEvent(t.name, ahead));
        }
      }
      if (!_arrived && match.alongM >= matcher.totalM - config.arrivalWithinM) {
        _arrived = true;
        events.add(const ArrivedEvent());
      }
    }

    _snapshot = _buildSnapshot(fix, match);
    events.addAll(tick(fix.time));
    return events;
  }

  List<NavigationEvent> tick(DateTime now) {
    final snap = _snapshot;
    final since = _offSince;
    if (snap == null || since == null || _arrived) return const [];

    final dist = snap.match.distanceToRouteM;
    if (!_warningActive && now.difference(since) >= config.offRouteDuration) {
      _warningActive = true;
      _lastWarning = now;
      _snapshot = _buildSnapshot(snap.fix, snap.match);
      return [OffRouteEvent(dist)];
    }
    if (_warningActive &&
        now.difference(_lastWarning!) >= config.repeatWarningAfter) {
      _lastWarning = now;
      return [OffRouteEvent(dist, repeated: true)];
    }
    return const [];
  }

  NavigationSnapshot _buildSnapshot(LocationFix fix, RouteMatch match) {
    RouteTarget? next;
    for (final t in targets) {
      if (t.alongM > match.alongM) {
        next = t;
        break;
      }
    }
    return NavigationSnapshot(
      fix: fix,
      match: match,
      remainingM: math.max(0, matcher.totalM - match.alongM),
      nextTarget: next,
      nextTargetDistanceM: next == null ? null : next.alongM - match.alongM,
      offRoute: _warningActive,
      arrived: _arrived,
    );
  }
}
