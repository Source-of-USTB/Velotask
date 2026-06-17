import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

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
  DateTimeColumn get lastCompletedDate => dateTime().nullable()();
  IntColumn get importance => integer().withDefault(const Constant(1))();
  // 0 = task, 1 = deadline  (enum index)
  IntColumn get taskType => integer().withDefault(const Constant(0))();
  RealColumn get estimatedEffortHours => real().nullable()();
  IntColumn get parentTodoId => integer().nullable().references(Todos, #id)();
  // 0 = none, 1 = subtasks, 2 = parallel
  IntColumn get groupMode => integer().withDefault(const Constant(0))();
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
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await _addTodoColumnIfMissing(
          m,
          'estimated_effort_hours',
          todos.estimatedEffortHours as GeneratedColumn<Object>,
        );
      }
      if (from < 3) {
        await _addTodoColumnIfMissing(
          m,
          'last_completed_date',
          todos.lastCompletedDate as GeneratedColumn<Object>,
        );
      }
      if (from < 4) {
        await _addTodoColumnIfMissing(
          m,
          'parent_todo_id',
          todos.parentTodoId as GeneratedColumn<Object>,
        );
        await _addTodoColumnIfMissing(
          m,
          'group_mode',
          todos.groupMode as GeneratedColumn<Object>,
        );
      }
    },
  );

  Future<void> _addTodoColumnIfMissing(
    Migrator migrator,
    String columnName,
    GeneratedColumn<Object> column,
  ) async {
    if (await _todoColumnExists(columnName)) {
      return;
    }
    await migrator.addColumn(todos, column);
  }

  Future<bool> _todoColumnExists(String columnName) async {
    final rows = await customSelect("PRAGMA table_info('todos')").get();
    return rows.any((row) => row.data['name'] == columnName);
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: kDebugMode ? 'velotask_debug_db' : 'velotask_db');
  }
}
