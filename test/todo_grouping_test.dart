import 'package:flutter_test/flutter_test.dart';
import 'package:velotask/models/todo.dart';

void main() {
  group('TaskGroupModeRules.requiresParent', () {
    test('none does not require parent', () {
      expect(TaskGroupMode.none.requiresParent, false);
    });

    test('subtasks requires parent', () {
      expect(TaskGroupMode.subtasks.requiresParent, true);
    });

    test('parallel requires parent', () {
      expect(TaskGroupMode.parallel.requiresParent, true);
    });
  });

  group('Todo.hasValidGrouping', () {
    test('none mode with no parent is valid', () {
      final t = Todo(title: 'x', groupMode: TaskGroupMode.none);
      expect(t.hasValidGrouping, true);
    });

    test('none mode with a parent is invalid', () {
      final t = Todo(
        title: 'x',
        groupMode: TaskGroupMode.none,
        parentTodoId: 1,
      );
      expect(t.hasValidGrouping, false);
    });

    test('subtasks mode with valid parent is valid', () {
      final t = Todo(
        id: 2,
        title: 'x',
        groupMode: TaskGroupMode.subtasks,
        parentTodoId: 1,
      );
      expect(t.hasValidGrouping, true);
    });

    test('subtasks mode without parent is invalid', () {
      final t = Todo(title: 'x', groupMode: TaskGroupMode.subtasks);
      expect(t.hasValidGrouping, false);
    });

    test('parallel mode with valid parent is valid', () {
      final t = Todo(
        id: 2,
        title: 'x',
        groupMode: TaskGroupMode.parallel,
        parentTodoId: 1,
        parallelPlan: 'A',
      );
      expect(t.hasValidGrouping, true);
    });

    test('parallel mode without parent is invalid', () {
      final t = Todo(
        title: 'x',
        groupMode: TaskGroupMode.parallel,
        parallelPlan: 'A',
      );
      expect(t.hasValidGrouping, false);
    });

    test('self-referencing parentTodoId is invalid for subtasks', () {
      final t = Todo(
        id: 1,
        title: 'x',
        groupMode: TaskGroupMode.subtasks,
        parentTodoId: 1,
      );
      expect(t.hasValidGrouping, false);
    });

    test('self-referencing parentTodoId is invalid for parallel', () {
      final t = Todo(
        id: 1,
        title: 'x',
        groupMode: TaskGroupMode.parallel,
        parentTodoId: 1,
        parallelPlan: 'A',
      );
      expect(t.hasValidGrouping, false);
    });

    test('parallel mode without a plan is invalid', () {
      final t = Todo(
        id: 2,
        title: 'x',
        groupMode: TaskGroupMode.parallel,
        parentTodoId: 1,
      );
      expect(t.hasValidGrouping, false);
    });

    test('parallel mode with a blank plan is invalid', () {
      final t = Todo(
        id: 2,
        title: 'x',
        groupMode: TaskGroupMode.parallel,
        parentTodoId: 1,
        parallelPlan: '   ',
      );
      expect(t.hasValidGrouping, false);
    });

    test('parallel mode with an oversized plan is invalid', () {
      final t = Todo(
        id: 2,
        title: 'x',
        groupMode: TaskGroupMode.parallel,
        parentTodoId: 1,
        parallelPlan: List.filled(Todo.maxParallelPlanLength + 1, 'A').join(),
      );
      expect(t.hasValidGrouping, false);
    });

    test('non-parallel mode with a plan is invalid', () {
      final t = Todo(
        id: 2,
        title: 'x',
        groupMode: TaskGroupMode.subtasks,
        parentTodoId: 1,
        parallelPlan: 'A',
      );
      expect(t.hasValidGrouping, false);
    });
  });

  group('Todo.normalizeParallelPlan', () {
    test('trims a plan identifier', () {
      expect(Todo.normalizeParallelPlan('  A  '), 'A');
    });

    test('turns blank identifiers into null', () {
      expect(Todo.normalizeParallelPlan('   '), isNull);
    });

    test('copyWith can clear a plan identifier', () {
      final todo = Todo(
        id: 2,
        title: 'x',
        groupMode: TaskGroupMode.parallel,
        parentTodoId: 1,
        parallelPlan: 'A',
      );

      expect(todo.copyWith(parallelPlan: null).parallelPlan, isNull);
    });
  });

  group('Todo.validateGrouping', () {
    test('does not throw for valid grouping', () {
      final t = Todo(title: 'x', groupMode: TaskGroupMode.none);
      expect(() => t.validateGrouping(), returnsNormally);
    });

    test('throws ArgumentError for invalid grouping', () {
      final t = Todo(
        title: 'x',
        groupMode: TaskGroupMode.subtasks,
        // no parentTodoId
      );
      expect(() => t.validateGrouping(), throwsArgumentError);
    });
  });

  group('Todo.hasParent', () {
    test('null parentTodoId returns false', () {
      final t = Todo(title: 'x');
      expect(t.hasParent, false);
    });

    test('non-null parentTodoId returns true', () {
      final t = Todo(title: 'x', parentTodoId: 1);
      expect(t.hasParent, true);
    });
  });
}
