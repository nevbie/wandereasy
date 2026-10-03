import 'package:xml/xml.dart';

import '../../../core/geo/lat_lng.dart';

/// Ein Punkt einer Route mit optionaler Höhe.
class TrackPoint {
  const TrackPoint(this.position, this.elevationM);

  final LatLng position;
  final double? elevationM;
}

class GpxFormatException implements Exception {
  GpxFormatException(this.message);

  final String message;

  @override
  String toString() => 'GpxFormatException: $message';
}

/// Liest alle Trackpunkte (`trkpt`) aus einer GPX-Datei, ersatzweise
/// Routenpunkte (`rtept`).
List<TrackPoint> parseGpx(String gpx) {
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(gpx);
  } on XmlException catch (e) {
    throw GpxFormatException('Keine gültige XML-Datei: ${e.message}');
  }

  var elements = doc.findAllElements('trkpt');
  if (elements.isEmpty) elements = doc.findAllElements('rtept');

  final points = <TrackPoint>[];
  for (final el in elements) {
    final lat = double.tryParse(el.getAttribute('lat') ?? '');
    final lon = double.tryParse(el.getAttribute('lon') ?? '');
    if (lat == null || lon == null) {
      throw GpxFormatException('Punkt ohne gültige Koordinaten');
    }
    final ele = el.getElement('ele')?.innerText;
    points.add(
      TrackPoint(LatLng(lat, lon), ele == null ? null : double.tryParse(ele)),
    );
  }
  if (points.length < 2) {
    throw GpxFormatException('Die Datei enthält keine Route');
  }
  return points;
}
