import 'package:velotask/models/todo.dart';

class TodoHierarchyNode {
  final Todo todo;
  final List<TodoHierarchyNode> children;

  TodoHierarchyNode({required this.todo, List<TodoHierarchyNode>? children})
    : children = children ?? [];

  bool get hasChildren => children.isNotEmpty;

  Iterable<TodoHierarchyNode> get descendants sync* {
    for (final child in children) {
      yield child;
      yield* child.descendants;
    }
  }

  int get descendantCount => descendants.length;

  int get doneDescendantCount =>
      descendants.where((node) => node.todo.isDone).length;
}

List<TodoHierarchyNode> buildTodoHierarchy(List<Todo> todos) {
  final todoById = <int, Todo>{};
  final nodeById = <int, TodoHierarchyNode>{};

  for (final todo in todos) {
    if (todo.id == 0) {
      continue;
    }
    todoById[todo.id] = todo;
    nodeById[todo.id] = TodoHierarchyNode(todo: todo);
  }

  final roots = <TodoHierarchyNode>[];
  for (final todo in todos) {
    final node = todo.id == 0
        ? TodoHierarchyNode(todo: todo)
        : nodeById[todo.id]!;
    final parentId = todo.parentTodoId;
    if (parentId == null || parentId == todo.id) {
      roots.add(node);
      continue;
    }

    final parent = nodeById[parentId];

    if (parent == null || _wouldCreateCycle(todo.id, parentId, todoById)) {
      roots.add(node);
      continue;
    }

    parent.children.add(node);
  }

  return roots;
}

List<TodoHierarchyNode> filterTodoHierarchy(
  List<TodoHierarchyNode> nodes,
  bool Function(Todo todo) matches,
) {
  final result = <TodoHierarchyNode>[];
  for (final node in nodes) {
    final children = filterTodoHierarchy(node.children, matches);
    if (matches(node.todo) || children.isNotEmpty) {
      result.add(TodoHierarchyNode(todo: node.todo, children: children));
    }
  }
  return result;
}

void sortTodoHierarchy(
  List<TodoHierarchyNode> nodes,
  Comparator<Todo> compare,
) {
  nodes.sort((a, b) => compare(a.todo, b.todo));
  for (final node in nodes) {
    sortTodoHierarchy(node.children, compare);
  }
}

bool hasTodoDescendant(TodoHierarchyNode node, int todoId) {
  return node.descendants.any((child) => child.todo.id == todoId);
}

bool _wouldCreateCycle(int childId, int parentId, Map<int, Todo> todoById) {
  var cursor = parentId;
  final seen = <int>{childId};

  while (true) {
    if (cursor == childId) {
      return true;
    }
    if (!seen.add(cursor)) {
      return true;
    }

    final parent = todoById[cursor];
    final next = parent?.parentTodoId;
    if (next == null) {
      return false;
    }
    cursor = next;
  }
}
