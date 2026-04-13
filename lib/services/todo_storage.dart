import 'package:drift/drift.dart';
import 'package:velotask/models/database.dart';
import 'package:velotask/models/tag.dart';
import 'package:velotask/models/todo.dart';

class TodoStorage {
  static final TodoStorage _instance = TodoStorage._internal();
  factory TodoStorage() => _instance;
  TodoStorage._internal();

  final AppDatabase _db = AppDatabase();

  String _normalizeTagName(String name) => name.trim().toLowerCase();

  Tag _rowToTag(TagRow row) =>
      Tag(id: row.id, name: row.name, color: row.color);

  Future<List<Tag>> _tagsForTodo(int todoId) async {
    final query = _db.select(_db.tags).join([
      innerJoin(_db.todoTags, _db.todoTags.tagId.equalsExp(_db.tags.id)),
    ])..where(_db.todoTags.todoId.equals(todoId));
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
    estimatedEffortHours: row.estimatedEffortHours,
    tags: tags,
  );

  Future<void> _saveTodoTags(int todoId, List<Tag> tags) async {
    await (_db.delete(
      _db.todoTags,
    )..where((tt) => tt.todoId.equals(todoId))).go();
    for (final tag in tags) {
      await _db
          .into(_db.todoTags)
          .insert(
            TodoTagsCompanion.insert(todoId: todoId, tagId: tag.id),
            mode: InsertMode.insertOrIgnore,
          );
    }
  }

  Future<List<Todo>> loadTodos() async {
    final rows = await _db.select(_db.todos).get();
    return Future.wait<Todo>(
      rows.map((row) async {
        final tags = await _tagsForTodo(row.id);
        return _rowToTodo(row, tags);
      }),
    );
  }

  Future<List<Tag>> loadTags() async {
    final rows = await _db.select(_db.tags).get();
    final dedup = <String, Tag>{};
    for (final row in rows) {
      final tag = _rowToTag(row);
      final key = _normalizeTagName(tag.name);
      dedup[key] = tag;
    }
    return dedup.values.toList();
  }

  Future<Tag> addTag(Tag tag) async {
    final trimmedName = tag.name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Tag name cannot be empty');
    }

    final existing =
        await (_db.select(_db.tags)
              ..where((t) => t.name.lower().equals(trimmedName.toLowerCase())))
            .getSingleOrNull();

    if (existing != null) {
      await (_db.update(
        _db.tags,
      )..where((t) => t.id.equals(existing.id))).write(
        TagsCompanion(
          name: Value(existing.name),
          color: Value(tag.color ?? existing.color),
        ),
      );
      final updated = await (_db.select(
        _db.tags,
      )..where((t) => t.id.equals(existing.id))).getSingle();
      return _rowToTag(updated);
    }

    final id = await _db
        .into(_db.tags)
        .insert(
          TagsCompanion.insert(name: trimmedName, color: Value(tag.color)),
        );
    final inserted = await (_db.select(
      _db.tags,
    )..where((t) => t.id.equals(id))).getSingle();
    return _rowToTag(inserted);
  }

  Future<void> deleteTag(int id) async {
    await (_db.delete(_db.todoTags)..where((tt) => tt.tagId.equals(id))).go();
    await (_db.delete(_db.tags)..where((t) => t.id.equals(id))).go();
  }

  Future<Todo> addTodo(Todo todo) async {
    final id = await _db
        .into(_db.todos)
        .insert(
          TodosCompanion.insert(
            title: todo.title,
            description: Value(todo.description),
            isCompleted: Value(todo.isCompleted),
            createdAt: Value(todo.createdAt),
            startDate: Value(todo.startDate),
            ddl: Value(todo.ddl),
            importance: Value(todo.importance),
            taskType: Value(todo.taskType.index),
            estimatedEffortHours: Value(todo.estimatedEffortHours),
          ),
        );
    await _saveTodoTags(id, todo.tags);
    return todo.copyWith(id: id);
  }

  Future<void> updateTodo(Todo todo, {bool saveLinks = true}) async {
    await (_db.update(_db.todos)..where((t) => t.id.equals(todo.id))).write(
      TodosCompanion(
        title: Value(todo.title),
        description: Value(todo.description),
        isCompleted: Value(todo.isCompleted),
        startDate: Value(todo.startDate),
        ddl: Value(todo.ddl),
        importance: Value(todo.importance),
        taskType: Value(todo.taskType.index),
        estimatedEffortHours: Value(todo.estimatedEffortHours),
      ),
    );
    if (saveLinks) {
      await _saveTodoTags(todo.id, todo.tags);
    }
  }

  Future<void> deleteTodo(int id) async {
    await (_db.delete(_db.todoTags)..where((tt) => tt.todoId.equals(id))).go();
    await (_db.delete(_db.todos)..where((t) => t.id.equals(id))).go();
  }

  static Future<void> close() async {
    await _instance._db.close();
  }
}
