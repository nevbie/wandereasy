import 'tour.dart';

/// Quelle der Touren. Demo-Daten jetzt, Supabase ab M5, Drift ab M2.
abstract interface class TourRepository {
  /// Alle veröffentlichten Touren.
  Future<List<Tour>> allTours();
}
