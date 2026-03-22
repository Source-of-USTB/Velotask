import 'package:drift/drift.dart';
import 'package:velotask/models/database.dart';
import 'package:velotask/models/tag.dart';
import 'package:velotask/models/todo.dart';

class TodoStorage {
  static final TodoStorage _instance = TodoStorage._internal();
  factory TodoStorage() => _instance;
  TodoStorage._internal();

  final AppDatabase _db = AppDatabase();

  // ---------------------------------------------------------------------------
  // Tag helpers
  // ---------------------------------------------------------------------------

  Tag _rowToTag(TagRow row) =>
      Tag(id: row.id, name: row.name, color: row.color);

  // ---------------------------------------------------------------------------
  // Tags CRUD
  // ---------------------------------------------------------------------------

  Future<List<Tag>> loadTags() async {
    final rows = await _db.select(_db.tags).get();
    return rows.map(_rowToTag).toList();
  }

  /// Inserts a new tag. If a tag with the same name already exists, updates
  /// its color and returns the existing record.
  Future<Tag> addTag(Tag tag) async {
    final id = await _db
        .into(_db.tags)
        .insertOnConflictUpdate(TagsCompanion.insert(
          name: tag.name,
          color: Value(tag.color),
        ));
    final row = await (_db.select(_db.tags)..where((t) => t.id.equals(id)))
        .getSingle();
    return _rowToTag(row);
  }

  Future<void> deleteTag(int id) async {
    // Remove junction rows first (cascade not configured at DB level).
    await (_db.delete(_db.todoTags)
          ..where((tt) => tt.tagId.equals(id)))
        .go();
    await (_db.delete(_db.tags)..where((t) => t.id.equals(id))).go();
  }

  // ---------------------------------------------------------------------------
  // Todo helpers
  // ---------------------------------------------------------------------------

  Future<List<Tag>> _tagsForTodo(int todoId) async {
    final query = _db.select(_db.tags).join([
      innerJoin(
        _db.todoTags,
        _db.todoTags.tagId.equalsExp(_db.tags.id),
      ),
    ])
      ..where(_db.todoTags.todoId.equals(todoId));
    final rows = await query.get();
    return rows.map((r) => _rowToTag(r.readTable(_db.tags))).toList();
  }

  Todo _rowToTodo(TodoRow row, List<Tag> tags) => Todo(
        id: row.id,
        title: row.title,
        description: row.description,
        isCompleted: row.isCompleted,
        createdAt: row.createdAt,
        startDate: row.startDate,
        ddl: row.ddl,
        importance: row.importance,
        taskType: TaskType.values[row.taskType],
        tags: tags,
      );

  Future<void> _saveTodoTags(int todoId, List<Tag> tags) async {
    await (_db.delete(_db.todoTags)
          ..where((tt) => tt.todoId.equals(todoId)))
        .go();
    for (final tag in tags) {
      await _db.into(_db.todoTags).insert(
            TodoTagsCompanion.insert(todoId: todoId, tagId: tag.id),
            mode: InsertMode.insertOrIgnore,
          );
    }
  }

  // ---------------------------------------------------------------------------
  // Todos CRUD
  // ---------------------------------------------------------------------------

  Future<List<Todo>> loadTodos() async {
    final rows = await _db.select(_db.todos).get();
    return Future.wait<Todo>(rows.map((row) async {
      final tags = await _tagsForTodo(row.id);
      return _rowToTodo(row, tags);
    }));
  }

  Future<Todo> addTodo(Todo todo) async {
    final id = await _db.into(_db.todos).insert(TodosCompanion.insert(
          title: todo.title,
          description: Value(todo.description),
          isCompleted: Value(todo.isCompleted),
          createdAt: Value(todo.createdAt),
          startDate: Value(todo.startDate),
          ddl: Value(todo.ddl),
          importance: Value(todo.importance),
          taskType: Value(todo.taskType.index),
        ));
    await _saveTodoTags(id, todo.tags);
    return todo.copyWith(id: id);
  }

  Future<void> updateTodo(Todo todo) async {
    await (_db.update(_db.todos)..where((t) => t.id.equals(todo.id)))
        .write(TodosCompanion(
          title: Value(todo.title),
          description: Value(todo.description),
          isCompleted: Value(todo.isCompleted),
          startDate: Value(todo.startDate),
          ddl: Value(todo.ddl),
          importance: Value(todo.importance),
          taskType: Value(todo.taskType.index),
        ));
    await _saveTodoTags(todo.id, todo.tags);
  }

  Future<void> deleteTodo(int id) async {
    await (_db.delete(_db.todoTags)..where((tt) => tt.todoId.equals(id))).go();
    await (_db.delete(_db.todos)..where((t) => t.id.equals(id))).go();
  }
}
