import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Für unterwegs gespeicherte Touren (SPEC 9). Die Tour liegt vollständig
/// als JSON vor, damit sie ohne Internet geöffnet werden kann.
@DataClassName('SavedTourRow')
class SavedTours extends Table {
  TextColumn get id => text()();
  TextColumn get json => text()();
  DateTimeColumn get savedAt => dateTime()();
  IntColumn get sizeBytes => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [SavedTours])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'wandern'));

  @override
  int get schemaVersion => 1;
}
