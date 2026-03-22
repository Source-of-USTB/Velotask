import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

// ---------------------------------------------------------------------------
// Tables
// ---------------------------------------------------------------------------

@DataClassName('TagRow')
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get color => text().nullable()(); // e.g. "#FF0000"
}

@DataClassName('TodoRow')
class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get ddl => dateTime().nullable()();
  IntColumn get importance => integer().withDefault(const Constant(1))();
  // 0 = task, 1 = deadline  (enum index)
  IntColumn get taskType => integer().withDefault(const Constant(0))();
}

/// Junction table for the many-to-many Todo ↔ Tag relationship.
class TodoTags extends Table {
  IntColumn get todoId => integer().references(Todos, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();

  @override
  Set<Column> get primaryKey => {todoId, tagId};
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

@DriftDatabase(tables: [Todos, Tags, TodoTags])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'velotask_db');
  }
}
