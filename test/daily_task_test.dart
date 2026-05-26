import 'package:flutter_test/flutter_test.dart';
import 'package:velotask/models/todo.dart';

void main() {
  group('Daily task isDone getter', () {
    test('lastCompletedDate is null → not done', () {
      final t = Todo(title: 'daily', taskType: TaskType.daily);
      expect(t.isDone, false);
    });

    test('lastCompletedDate is today → done', () {
      final t = Todo(
        title: 'daily',
        taskType: TaskType.daily,
        lastCompletedDate: DateTime.now(),
      );
      expect(t.isDone, true);
    });

    test('lastCompletedDate is yesterday → not done', () {
      final t = Todo(
        title: 'daily',
        taskType: TaskType.daily,
        lastCompletedDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(t.isDone, false);
    });

    test('non-daily task falls back to isCompleted', () {
      final active = Todo(title: 'x', isCompleted: false);
      final completed = Todo(title: 'y', isCompleted: true);

      expect(active.isDone, false);
      expect(completed.isDone, true);
    });

    test('deadline task falls back to isCompleted', () {
      final t = Todo(
        title: 'deadline',
        taskType: TaskType.deadline,
        isCompleted: true,
        lastCompletedDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(t.isDone, true);
    });
  });

  group('LastCompletedDate toggling logic', () {
    test('completed today → toggling should clear lastCompletedDate', () {
      final t = Todo(
        title: 'daily',
        taskType: TaskType.daily,
        lastCompletedDate: DateTime.now(),
      );
      // Simulate what _toggleTodo does for daily tasks
      t.lastCompletedDate = t.isDone ? null : DateTime.now();
      expect(t.lastCompletedDate, isNull);
      expect(t.isDone, false);
    });

    test('not completed today → toggling should set lastCompletedDate to now', () {
      final t = Todo(title: 'daily', taskType: TaskType.daily);
      t.lastCompletedDate = t.isDone ? null : DateTime.now();
      expect(t.lastCompletedDate, isNotNull);
      expect(t.isDone, true);
    });
  });
}
