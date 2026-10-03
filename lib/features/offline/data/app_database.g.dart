// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SavedToursTable extends SavedTours
    with TableInfo<$SavedToursTable, SavedTourRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedToursTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta(
    'savedAt',
  );
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
    'saved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, json, savedAt, sizeBytes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_tours';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedTourRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('saved_at')) {
      context.handle(
        _savedAtMeta,
        savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavedTourRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedTourRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      savedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}saved_at'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
    );
  }

  @override
  $SavedToursTable createAlias(String alias) {
    return $SavedToursTable(attachedDatabase, alias);
  }
}

class SavedTourRow extends DataClass implements Insertable<SavedTourRow> {
  final String id;
  final String json;
  final DateTime savedAt;
  final int sizeBytes;
  const SavedTourRow({
    required this.id,
    required this.json,
    required this.savedAt,
    required this.sizeBytes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['json'] = Variable<String>(json);
    map['saved_at'] = Variable<DateTime>(savedAt);
    map['size_bytes'] = Variable<int>(sizeBytes);
    return map;
  }

  SavedToursCompanion toCompanion(bool nullToAbsent) {
    return SavedToursCompanion(
      id: Value(id),
      json: Value(json),
      savedAt: Value(savedAt),
      sizeBytes: Value(sizeBytes),
    );
  }

  factory SavedTourRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedTourRow(
      id: serializer.fromJson<String>(json['id']),
      json: serializer.fromJson<String>(json['json']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'json': serializer.toJson<String>(json),
      'savedAt': serializer.toJson<DateTime>(savedAt),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
    };
  }

  SavedTourRow copyWith({
    String? id,
    String? json,
    DateTime? savedAt,
    int? sizeBytes,
  }) => SavedTourRow(
    id: id ?? this.id,
    json: json ?? this.json,
    savedAt: savedAt ?? this.savedAt,
    sizeBytes: sizeBytes ?? this.sizeBytes,
  );
  SavedTourRow copyWithCompanion(SavedToursCompanion data) {
    return SavedTourRow(
      id: data.id.present ? data.id.value : this.id,
      json: data.json.present ? data.json.value : this.json,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedTourRow(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('savedAt: $savedAt, ')
          ..write('sizeBytes: $sizeBytes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, json, savedAt, sizeBytes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedTourRow &&
          other.id == this.id &&
          other.json == this.json &&
          other.savedAt == this.savedAt &&
          other.sizeBytes == this.sizeBytes);
}

class SavedToursCompanion extends UpdateCompanion<SavedTourRow> {
  final Value<String> id;
  final Value<String> json;
  final Value<DateTime> savedAt;
  final Value<int> sizeBytes;
  final Value<int> rowid;
  const SavedToursCompanion({
    this.id = const Value.absent(),
    this.json = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedToursCompanion.insert({
    required String id,
    required String json,
    required DateTime savedAt,
    required int sizeBytes,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       json = Value(json),
       savedAt = Value(savedAt),
       sizeBytes = Value(sizeBytes);
  static Insertable<SavedTourRow> custom({
    Expression<String>? id,
    Expression<String>? json,
    Expression<DateTime>? savedAt,
    Expression<int>? sizeBytes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (json != null) 'json': json,
      if (savedAt != null) 'saved_at': savedAt,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedToursCompanion copyWith({
    Value<String>? id,
    Value<String>? json,
    Value<DateTime>? savedAt,
    Value<int>? sizeBytes,
    Value<int>? rowid,
  }) {
    return SavedToursCompanion(
      id: id ?? this.id,
      json: json ?? this.json,
      savedAt: savedAt ?? this.savedAt,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedToursCompanion(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('savedAt: $savedAt, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SavedToursTable savedTours = $SavedToursTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [savedTours];
}

typedef $$SavedToursTableCreateCompanionBuilder = SavedToursCompanion Function({
  required String id,
  required String json,
  required DateTime savedAt,
  required int sizeBytes,
  Value<int> rowid,
});
typedef $$SavedToursTableUpdateCompanionBuilder = SavedToursCompanion Function({
  Value<String> id,
  Value<String> json,
  Value<DateTime> savedAt,
  Value<int> sizeBytes,
  Value<int> rowid,
});

class $$SavedToursTableFilterComposer
    extends Composer<_$AppDatabase, $SavedToursTable> {
  $$SavedToursTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavedToursTableOrderingComposer
    extends Composer<_$AppDatabase, $SavedToursTable> {
  $$SavedToursTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavedToursTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavedToursTable> {
  $$SavedToursTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);
}

class $$SavedToursTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavedToursTable,
          SavedTourRow,
          $$SavedToursTableFilterComposer,
          $$SavedToursTableOrderingComposer,
          $$SavedToursTableAnnotationComposer,
          $$SavedToursTableCreateCompanionBuilder,
          $$SavedToursTableUpdateCompanionBuilder,
          (
            SavedTourRow,
            BaseReferences<_$AppDatabase, $SavedToursTable, SavedTourRow>,
          ),
          SavedTourRow,
          PrefetchHooks Function()
        > {
  $$SavedToursTableTableManager(_$AppDatabase db, $SavedToursTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedToursTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedToursTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedToursTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<DateTime> savedAt = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedToursCompanion(
                id: id,
                json: json,
                savedAt: savedAt,
                sizeBytes: sizeBytes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String json,
                required DateTime savedAt,
                required int sizeBytes,
                Value<int> rowid = const Value.absent(),
              }) => SavedToursCompanion.insert(
                id: id,
                json: json,
                savedAt: savedAt,
                sizeBytes: sizeBytes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SavedToursTable, SavedTourRow>(table),
                  BaseReferences<_$AppDatabase, $SavedToursTable, SavedTourRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavedToursTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavedToursTable,
      SavedTourRow,
      $$SavedToursTableFilterComposer,
      $$SavedToursTableOrderingComposer,
      $$SavedToursTableAnnotationComposer,
      $$SavedToursTableCreateCompanionBuilder,
      $$SavedToursTableUpdateCompanionBuilder,
      (
        SavedTourRow,
        BaseReferences<_$AppDatabase, $SavedToursTable, SavedTourRow>,
      ),
      SavedTourRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SavedToursTableTableManager get savedTours =>
      $$SavedToursTableTableManager(_db, _db.savedTours);
}
