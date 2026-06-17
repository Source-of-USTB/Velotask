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

  @override
  List<String> get customConstraints => [
    'CHECK (group_mode IN (0, 1, 2))',
    'CHECK ((group_mode = 0 AND parent_todo_id IS NULL) OR '
        '(group_mode IN (1, 2) AND parent_todo_id IS NOT NULL))',
    'CHECK (parent_todo_id IS NULL OR parent_todo_id != id)',
  ];
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
    beforeOpen: (_) async {
      await _normalizeTodoGroupingRows();
      await _ensureTodoGroupingTriggers();
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

  Future<void> _normalizeTodoGroupingRows() async {
    await customStatement(
      'UPDATE todos SET group_mode = 0 '
      'WHERE group_mode NOT IN (0, 1, 2);',
    );
    await customStatement(
      'UPDATE todos SET group_mode = 0, parent_todo_id = NULL '
      'WHERE parent_todo_id = id;',
    );
    await customStatement(
      'UPDATE todos SET parent_todo_id = NULL WHERE group_mode = 0;',
    );
    await customStatement(
      'UPDATE todos SET group_mode = 0 '
      'WHERE group_mode != 0 AND parent_todo_id IS NULL;',
    );
    await customStatement(
      'UPDATE todos SET group_mode = 0, parent_todo_id = NULL '
      'WHERE parent_todo_id IS NOT NULL '
      'AND NOT EXISTS ('
      'SELECT 1 FROM todos parents WHERE parents.id = todos.parent_todo_id'
      ');',
    );
  }

  Future<void> _ensureTodoGroupingTriggers() async {
    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS todos_grouping_insert_check '
      'BEFORE INSERT ON todos '
      'WHEN NEW.group_mode NOT IN (0, 1, 2) '
      'OR (NEW.group_mode = 0 AND NEW.parent_todo_id IS NOT NULL) '
      'OR (NEW.group_mode IN (1, 2) AND NEW.parent_todo_id IS NULL) '
      'OR (NEW.parent_todo_id IS NOT NULL AND NEW.parent_todo_id = NEW.id) '
      'OR (NEW.parent_todo_id IS NOT NULL AND NOT EXISTS ('
      'SELECT 1 FROM todos parents WHERE parents.id = NEW.parent_todo_id'
      ')) '
      'BEGIN '
      "SELECT RAISE(ABORT, 'invalid todo grouping'); "
      'END;',
    );
    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS todos_grouping_update_check '
      'BEFORE UPDATE OF group_mode, parent_todo_id ON todos '
      'WHEN NEW.group_mode NOT IN (0, 1, 2) '
      'OR (NEW.group_mode = 0 AND NEW.parent_todo_id IS NOT NULL) '
      'OR (NEW.group_mode IN (1, 2) AND NEW.parent_todo_id IS NULL) '
      'OR (NEW.parent_todo_id IS NOT NULL AND NEW.parent_todo_id = NEW.id) '
      'OR (NEW.parent_todo_id IS NOT NULL AND NOT EXISTS ('
      'SELECT 1 FROM todos parents WHERE parents.id = NEW.parent_todo_id'
      ')) '
      'BEGIN '
      "SELECT RAISE(ABORT, 'invalid todo grouping'); "
      'END;',
    );
    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS todos_grouping_delete_check '
      'BEFORE DELETE ON todos '
      'WHEN EXISTS ('
      'SELECT 1 FROM todos children WHERE children.parent_todo_id = OLD.id'
      ') '
      'BEGIN '
      "SELECT RAISE(ABORT, 'todo has grouped children'); "
      'END;',
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: kDebugMode ? 'velotask_debug_db' : 'velotask_db');
  }
}
