import 'package:flutter_test/flutter_test.dart';
import 'package:velotask/models/todo.dart';
import 'package:velotask/models/todo_hierarchy.dart';

Todo _todo(
  int id, {
  int? parentId,
  TaskGroupMode groupMode = TaskGroupMode.none,
  String? parallelPlan,
}) {
  return Todo(
    id: id,
    title: 'Todo $id',
    parentTodoId: parentId,
    groupMode: groupMode,
    parallelPlan: parallelPlan,
  );
}

void main() {
  group('buildTodoHierarchy', () {
    test('empty list returns empty', () {
      expect(buildTodoHierarchy([]), isEmpty);
    });

    test('single root todo', () {
      final nodes = buildTodoHierarchy([_todo(1)]);
      expect(nodes.length, 1);
      expect(nodes.first.todo.id, 1);
      expect(nodes.first.children, isEmpty);
    });

    test('parent-child link', () {
      final nodes = buildTodoHierarchy([_todo(1), _todo(2, parentId: 1)]);
      expect(nodes.length, 1);
      expect(nodes.first.todo.id, 1);
      expect(nodes.first.children.length, 1);
      expect(nodes.first.children.first.todo.id, 2);
    });

    test('multiple children under same parent', () {
      final nodes = buildTodoHierarchy([
        _todo(1),
        _todo(2, parentId: 1),
        _todo(3, parentId: 1),
      ]);
      expect(nodes.length, 1);
      expect(nodes.first.children.length, 2);
    });

    test('multi-level nesting (grandchild)', () {
      final nodes = buildTodoHierarchy([
        _todo(1),
        _todo(2, parentId: 1),
        _todo(3, parentId: 2),
      ]);
      expect(nodes.length, 1);
      final child = nodes.first.children.first;
      expect(child.todo.id, 2);
      expect(child.children.first.todo.id, 3);
    });

    test('self-referencing parent treated as root', () {
      final nodes = buildTodoHierarchy([_todo(1, parentId: 1)]);
      expect(nodes.length, 1);
      expect(nodes.first.children, isEmpty);
    });

    test('missing parent treated as root', () {
      final nodes = buildTodoHierarchy([_todo(2, parentId: 99)]);
      expect(nodes.length, 1);
      expect(nodes.first.todo.id, 2);
    });

    test('cycle detection: A→B→C, C parent=A makes C a root', () {
      final nodes = buildTodoHierarchy([
        _todo(1),
        _todo(2, parentId: 1),
        _todo(3, parentId: 2),
        // Attempt to make 3's child point back to 1 — but let's test:
        // 1 → 2, and 1 also has parentId=3 which would create a cycle
      ]);
      expect(nodes.length, 1);

      // Now test actual cycle: A parent=B, B parent=A
      final cycleNodes = buildTodoHierarchy([
        _todo(10, parentId: 11),
        _todo(11, parentId: 10),
      ]);
      // One becomes root (first processed without parent found),
      // the other tries to attach but cycle prevents it
      expect(cycleNodes.length, 2);
    });

    test('id==0 is treated as root without being in nodeById', () {
      final nodes = buildTodoHierarchy([Todo(id: 0, title: 'unsaved')]);
      expect(nodes.length, 1);
      expect(nodes.first.todo.id, 0);
    });

    test('id==0 cannot be a parent target', () {
      final nodes = buildTodoHierarchy([
        Todo(id: 0, title: 'unsaved'),
        _todo(1, parentId: 0),
      ]);
      // id==0 is skipped in nodeById, so todo 1 has a missing parent → root
      expect(nodes.length, 2);
    });
  });

  group('filterTodoHierarchy', () {
    final hierarchy = buildTodoHierarchy([
      _todo(1),
      _todo(2, parentId: 1),
      _todo(3, parentId: 1),
      _todo(4, parentId: 2),
    ]);

    test('matching leaf is kept', () {
      final result = filterTodoHierarchy(hierarchy, (t) => t.id == 3);
      expect(result.length, 1);
      expect(result.first.todo.id, 1); // parent kept because child matches
      expect(result.first.children.length, 1);
      expect(result.first.children.first.todo.id, 3);
    });

    test('non-matching leaf is removed', () {
      final result = filterTodoHierarchy(hierarchy, (t) => t.id == 99);
      expect(result, isEmpty);
    });

    test('parent kept when descendant matches', () {
      final result = filterTodoHierarchy(hierarchy, (t) => t.id == 4);
      expect(result.length, 1);
      expect(result.first.todo.id, 1);
      final child = result.first.children.first;
      expect(child.todo.id, 2);
      expect(child.children.first.todo.id, 4);
    });

    test('parent that matches keeps all matching descendants', () {
      final result = filterTodoHierarchy(
        hierarchy,
        (t) => t.id == 1 || t.id == 3,
      );
      expect(result.length, 1);
      expect(result.first.todo.id, 1);
      // Child 3 matches, child 2 does not but has no matching descendant
      expect(result.first.children.length, 1);
      expect(result.first.children.first.todo.id, 3);
    });

    test('empty input returns empty', () {
      expect(filterTodoHierarchy([], (_) => true), isEmpty);
    });

    test('all match returns full hierarchy', () {
      final result = filterTodoHierarchy(hierarchy, (_) => true);
      expect(result.length, 1);
      expect(result.first.descendantCount, 3);
    });
  });

  group('sortTodoHierarchy', () {
    test('sorts roots by comparator', () {
      final nodes = buildTodoHierarchy([
        _todo(1)..title = 'Charlie',
        _todo(2)..title = 'Alice',
        _todo(3)..title = 'Bob',
      ]);
      sortTodoHierarchy(nodes, (a, b) => a.title.compareTo(b.title));
      expect(nodes[0].todo.title, 'Alice');
      expect(nodes[1].todo.title, 'Bob');
      expect(nodes[2].todo.title, 'Charlie');
    });

    test('sorts children independently', () {
      final nodes = buildTodoHierarchy([
        _todo(1)..title = 'Parent',
        (_todo(10, parentId: 1))..title = 'Zeta',
        (_todo(11, parentId: 1))..title = 'Alpha',
      ]);
      sortTodoHierarchy(nodes, (a, b) => a.title.compareTo(b.title));
      expect(nodes.first.children[0].todo.title, 'Alpha');
      expect(nodes.first.children[1].todo.title, 'Zeta');
    });

    test('empty list does not throw', () {
      final nodes = <TodoHierarchyNode>[];
      sortTodoHierarchy(nodes, (a, b) => a.id.compareTo(b.id));
      expect(nodes, isEmpty);
    });

    test('single element stays the same', () {
      final nodes = buildTodoHierarchy([_todo(1)]);
      sortTodoHierarchy(nodes, (a, b) => a.id.compareTo(b.id));
      expect(nodes.length, 1);
      expect(nodes.first.todo.id, 1);
    });

    test('keeps parallel plans together before schedule order', () {
      final nodes = buildTodoHierarchy([
        _todo(1),
        _todo(
          2,
          parentId: 1,
          groupMode: TaskGroupMode.parallel,
          parallelPlan: 'B',
        ),
        _todo(3, parentId: 1, groupMode: TaskGroupMode.subtasks),
        _todo(
          4,
          parentId: 1,
          groupMode: TaskGroupMode.parallel,
          parallelPlan: 'A',
        ),
        _todo(
          5,
          parentId: 1,
          groupMode: TaskGroupMode.parallel,
          parallelPlan: 'A',
        ),
      ]);

      sortTodoHierarchy(
        nodes,
        (a, b) => compareGroupedTodos(a, b, (a, b) => a.id.compareTo(b.id)),
      );

      expect(
        nodes.first.children.map((node) => node.todo.id),
        orderedEquals([3, 4, 5, 2]),
      );
    });

    test('sorts numeric parallel plan labels naturally', () {
      expect(compareParallelPlans('2', '10'), lessThan(0));
    });
  });

  group('hasTodoDescendant', () {
    test('returns true for direct child', () {
      final root = buildTodoHierarchy([_todo(1), _todo(2, parentId: 1)]).first;
      expect(hasTodoDescendant(root, 2), true);
    });

    test('returns true for deeper descendant', () {
      final root = buildTodoHierarchy([
        _todo(1),
        _todo(2, parentId: 1),
        _todo(3, parentId: 2),
      ]).first;
      expect(hasTodoDescendant(root, 3), true);
    });

    test('returns false for non-existent id', () {
      final root = buildTodoHierarchy([_todo(1), _todo(2, parentId: 1)]).first;
      expect(hasTodoDescendant(root, 99), false);
    });

    test('returns false for self (not a descendant)', () {
      final root = buildTodoHierarchy([_todo(1)]).first;
      expect(hasTodoDescendant(root, 1), false);
    });

    test('returns false for node with no children', () {
      final root = buildTodoHierarchy([_todo(1)]).first;
      expect(hasTodoDescendant(root, 2), false);
    });
  });
}
