import 'package:flutter_test/flutter_test.dart';
import 'package:velotask/models/todo.dart';
import 'package:velotask/utils/priority_engine.dart';

void main() {
  group('PriorityEngine v1/v2 urgency', () {
    final now = DateTime(2026, 3, 5, 10);

    test('balanced model hits target anchors for 1h task', () {
      Todo taskAt(Duration offset) =>
          Todo(title: 'anchor task 1h', importance: 1, ddl: now.add(offset));

      final at8h = PriorityEngine.urgencyRatioV2(
        taskAt(const Duration(hours: 8)),
        now: now,
      );
      final at1d = PriorityEngine.urgencyRatioV2(
        taskAt(const Duration(hours: 24)),
        now: now,
      );
      final at3d = PriorityEngine.urgencyRatioV2(
        taskAt(const Duration(hours: 72)),
        now: now,
      );
      final at7d = PriorityEngine.urgencyRatioV2(
        taskAt(const Duration(hours: 168)),
        now: now,
      );

      expect(at8h, closeTo(0.99, 0.03));
      expect(at1d, closeTo(0.70, 0.03));
      expect(at3d, closeTo(0.40, 0.03));
      expect(at7d, closeTo(0.20, 0.03));
    });

    test('v1 uses E/R and classifies thresholds', () {
      final relaxed = Todo(
        title: 'quick task 1h',
        importance: 1,
        ddl: now.add(const Duration(hours: 20)),
      );
      final medium = Todo(
        title: 'medium task 3h',
        importance: 1,
        ddl: now.add(const Duration(hours: 8)),
      );
      final high = Todo(
        title: 'hard task 5h',
        importance: 1,
        ddl: now.add(const Duration(hours: 6)),
      );

      expect(PriorityEngine.urgencyRatioV1(relaxed, now: now), lessThan(0.3));
      expect(
        PriorityEngine.urgencyRatioV1(medium, now: now),
        inInclusiveRange(0.3, 0.7),
      );
      expect(
        PriorityEngine.urgencyRatioV1(high, now: now),
        greaterThanOrEqualTo(0.7),
      );
    });

    test('v2 urgency is higher when deadline is nearer', () {
      final near = Todo(
        title: 'same effort 3h',
        importance: 1,
        ddl: now.add(const Duration(hours: 4)),
      );
      final far = Todo(
        title: 'same effort 3h',
        importance: 1,
        ddl: now.add(const Duration(hours: 24)),
      );

      expect(
        PriorityEngine.urgencyRatioV2(near, now: now),
        greaterThan(PriorityEngine.urgencyRatioV2(far, now: now)),
      );
    });

    test('completed task is deprioritized', () {
      final done = Todo(
        title: 'done 2h',
        importance: 2,
        ddl: now.add(const Duration(hours: 2)),
        isCompleted: true,
      );

      expect(PriorityEngine.score(done, now: now), lessThan(0));
      expect(
        PriorityEngine.notificationTier(done, now: now),
        PriorityNotificationTier.none,
      );
    });
  });

  group('PriorityEngine v3/v4 score and ordering', () {
    final now = DateTime(2026, 3, 5, 10);

    test('priority contributes but urgency dominates', () {
      final highPriorityFar = Todo(
        title: 'far 2h',
        importance: 2,
        ddl: now.add(const Duration(days: 5)),
      );
      final lowPriorityNear = Todo(
        title: 'near 4h',
        importance: 0,
        ddl: now.add(const Duration(hours: 5)),
      );

      expect(
        PriorityEngine.score(lowPriorityNear, now: now),
        greaterThan(PriorityEngine.score(highPriorityFar, now: now)),
      );
    });

    test('overload coupling boosts urgency under heavy load', () {
      final base = Todo(
        title: 'base 3h',
        importance: 1,
        ddl: now.add(const Duration(hours: 12)),
      );
      final normalLoad = [base];
      final heavyLoad = [
        base,
        Todo(
          title: 'x1 8h',
          importance: 2,
          ddl: now.add(const Duration(hours: 10)),
        ),
        Todo(
          title: 'x2 8h',
          importance: 2,
          ddl: now.add(const Duration(hours: 10)),
        ),
      ];

      expect(
        PriorityEngine.urgency(base, allTodos: heavyLoad, now: now),
        greaterThan(
          PriorityEngine.urgency(base, allTodos: normalLoad, now: now),
        ),
      );
    });

    test('sortedTodos places theoretically late task first', () {
      final impossible = Todo(
        title: 'impossible 10h',
        importance: 1,
        ddl: now.add(const Duration(hours: 2)),
      );
      final relaxed = Todo(
        title: 'relaxed 1h',
        importance: 2,
        ddl: now.add(const Duration(days: 3)),
      );

      final sorted = PriorityEngine.sortedTodos([
        relaxed,
        impossible,
      ], now: now);
      expect(sorted.first.title, 'impossible 10h');
      expect(PriorityEngine.isTheoreticallyLate(impossible, now: now), isTrue);
    });

    test('notification tier maps to urgency band', () {
      final urgent = Todo(
        title: 'urgent 6h',
        importance: 2,
        ddl: now.add(const Duration(hours: 3)),
      );
      final normal = Todo(
        title: 'normal 1h',
        importance: 1,
        ddl: now.add(const Duration(days: 2)),
      );

      expect(
        PriorityEngine.notificationTier(urgent, now: now),
        anyOf(PriorityNotificationTier.high, PriorityNotificationTier.medium),
      );
      expect(
        PriorityEngine.notificationTier(normal, now: now),
        anyOf(
          PriorityNotificationTier.none,
          PriorityNotificationTier.low,
          PriorityNotificationTier.medium,
        ),
      );
    });
  });
}
