import 'package:velotask/models/tag.dart';
import 'package:velotask/models/todo.dart';

class TodoStorage {
  static final TodoStorage _instance = TodoStorage._internal();
  factory TodoStorage() => _instance;
  TodoStorage._internal();

  static final List<Tag> _tags = [];
  static final List<Todo> _todos = [];
  static int _nextTagId = 1;
  static int _nextTodoId = 1;

  Tag _cloneTag(Tag tag) => tag.copyWith();

  Todo _cloneTodo(Todo todo) =>
      todo.copyWith(tags: todo.tags.map(_cloneTag).toList());

  Future<List<Tag>> loadTags() async {
    return _tags.map(_cloneTag).toList();
  }

  Future<Tag> addTag(Tag tag) async {
    final index = _tags.indexWhere((item) => item.name == tag.name);
    if (index != -1) {
      _tags[index] = _tags[index].copyWith(color: tag.color);
      return _cloneTag(_tags[index]);
    }

    final savedTag = tag.copyWith(id: _nextTagId++);
    _tags.add(savedTag);
    return _cloneTag(savedTag);
  }

  Future<void> deleteTag(int id) async {
    _tags.removeWhere((tag) => tag.id == id);
    for (final todo in _todos) {
      todo.tags = todo.tags.where((tag) => tag.id != id).toList();
    }
  }

  Future<List<Todo>> loadTodos() async {
    final todos = [..._todos]..sort((a, b) => a.id.compareTo(b.id));
    return todos.map(_cloneTodo).toList();
  }

  Future<Todo> addTodo(Todo todo) async {
    final savedTodo = todo.copyWith(
      id: _nextTodoId++,
      tags: todo.tags
          .map(
            (tag) => _tags.firstWhere(
              (item) => item.id == tag.id,
              orElse: () => tag,
            ),
          )
          .map(_cloneTag)
          .toList(),
    );
    _todos.add(savedTodo);
    return _cloneTodo(savedTodo);
  }

  Future<void> updateTodo(Todo todo) async {
    final index = _todos.indexWhere((item) => item.id == todo.id);
    if (index == -1) return;

    _todos[index] = todo.copyWith(
      tags: todo.tags
          .map(
            (tag) => _tags.firstWhere(
              (item) => item.id == tag.id,
              orElse: () => tag,
            ),
          )
          .map(_cloneTag)
          .toList(),
    );
  }

  Future<void> deleteTodo(int id) async {
    _todos.removeWhere((todo) => todo.id == id);
  }
}
