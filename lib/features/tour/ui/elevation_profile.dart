import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../domain/route_stats.dart';
import 'tour_format.dart';

/// Höhenprofil als Flächendiagramm. Beschriftungen sind normale Texte,
/// damit sie mit der Schriftgröße wachsen.
class ElevationProfile extends StatelessWidget {
  const ElevationProfile({super.key, required this.profile});

  final List<ElevationPoint> profile;

  @override
  Widget build(BuildContext context) {
    if (profile.length < 2) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final eles = profile.map((p) => p.elevationM);
    final minEle = eles.reduce(math.min).round();
    final maxEle = eles.reduce(math.max).round();
    final total = formatKm(l10n, profile.last.distanceM);

    return Semantics(
      container: true,
      label: l10n.elevationSemantics(total, minEle, maxEle),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 160,
              child: CustomPaint(
                painter: _ProfilePainter(
                  profile: profile,
                  line: theme.colorScheme.primary,
                  fill: theme.colorScheme.primary.withValues(alpha: 0.2),
                  grid: theme.colorScheme.outlineVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Wrap statt Row: bei großer Schrift untereinander statt Überlauf.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 16,
              children: [
                Text(l10n.distanceKm('0'), style: theme.textTheme.bodyMedium),
                Text(total, style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.elevationRange(minEle, maxEle),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePainter extends CustomPainter {
  _ProfilePainter({
    required this.profile,
    required this.line,
    required this.fill,
    required this.grid,
  });

  final List<ElevationPoint> profile;
  final Color line;
  final Color fill;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    final maxD = profile.last.distanceM;
    var minE = profile.first.elevationM;
    var maxE = minE;
    for (final p in profile) {
      minE = math.min(minE, p.elevationM);
      maxE = math.max(maxE, p.elevationM);
    }
    // Mindestens 50 m Spanne, damit flache Touren nicht dramatisch wirken.
    final span = math.max(50.0, maxE - minE);
    final base = minE - span * 0.1;
    final range = span * 1.2;

    Offset at(ElevationPoint p) => Offset(
      maxD == 0 ? 0 : p.distanceM / maxD * size.width,
      size.height - (p.elevationM - base) / range * size.height,
    );

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final y = size.height * i / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path()..moveTo(at(profile.first).dx, at(profile.first).dy);
    for (final p in profile.skip(1)) {
      final o = at(p);
      path.lineTo(o.dx, o.dy);
    }
    final area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas
      ..drawPath(area, Paint()..color = fill)
      ..drawPath(
        path,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round,
      );
  }

  @override
  bool shouldRepaint(_ProfilePainter old) =>
      old.profile != profile || old.line != line || old.fill != fill;
}
