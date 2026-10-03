import 'dart:convert';

import 'package:drift/drift.dart';

import '../../tour/data/tour_codec.dart';
import '../../tour/domain/tour.dart';
import 'app_database.dart';

/// Eine für unterwegs gespeicherte Tour.
class SavedTour {
  const SavedTour({
    required this.tour,
    required this.savedAt,
    required this.sizeBytes,
  });

  final Tour tour;
  final DateTime savedAt;
  final int sizeBytes;
}

class SavedToursRepository {
  SavedToursRepository(this._db);

  final AppDatabase _db;

  /// Ungefährer Speicherbedarf einer Tour in Bytes.
  static int estimateSizeBytes(Tour tour) =>
      utf8.encode(jsonEncode(TourCodec.toJson(tour))).length;

  Future<void> save(Tour tour, {DateTime? now}) {
    final json = jsonEncode(TourCodec.toJson(tour));
    return _db
        .into(_db.savedTours)
        .insertOnConflictUpdate(
          SavedToursCompanion.insert(
            id: tour.id,
            json: json,
            savedAt: now ?? DateTime.now(),
            sizeBytes: utf8.encode(json).length,
          ),
        );
  }

  Future<void> delete(String id) =>
      (_db.delete(_db.savedTours)..where((t) => t.id.equals(id))).go();

  /// Alle gespeicherten Touren, neueste zuerst.
  Stream<List<SavedTour>> watchAll() =>
      (_db.select(_db.savedTours)
            ..orderBy([(t) => OrderingTerm.desc(t.savedAt)]))
          .watch()
          .map((rows) => rows.map(_fromRow).toList());

  Future<Tour?> get(String id) async {
    final row = await (_db.select(
      _db.savedTours,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _fromRow(row).tour;
  }

  SavedTour _fromRow(SavedTourRow row) => SavedTour(
    tour: TourCodec.fromJson(jsonDecode(row.json) as Map<String, dynamic>),
    savedAt: row.savedAt,
    sizeBytes: row.sizeBytes,
  );
}
