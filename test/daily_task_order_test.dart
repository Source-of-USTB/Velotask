import 'package:flutter_test/flutter_test.dart';
import 'package:velotask/services/daily_task_order_controller.dart';

void main() {
  group('normalizeOrder', () {
    test('empty order and empty ids returns empty', () {
      expect(
        DailyTaskOrderController.normalizeOrder(
          currentOrder: [],
          dailyTodoIds: [],
        ),
        isEmpty,
      );
    });

    test('empty order with new ids returns ids in iteration order', () {
      expect(
        DailyTaskOrderController.normalizeOrder(
          currentOrder: [],
          dailyTodoIds: [3, 1, 2],
        ),
        [3, 1, 2],
      );
    });

    test('preserves order of valid ids, appends new ones', () {
      expect(
        DailyTaskOrderController.normalizeOrder(
          currentOrder: [2, 1],
          dailyTodoIds: [1, 2, 3],
        ),
        [2, 1, 3],
      );
    });

    test('removes ids not in dailyTodoIds', () {
      expect(
        DailyTaskOrderController.normalizeOrder(
          currentOrder: [5, 1, 2],
          dailyTodoIds: [1, 2, 3],
        ),
        [1, 2, 3],
      );
    });

    test('deduplicates currentOrder (first occurrence wins)', () {
      expect(
        DailyTaskOrderController.normalizeOrder(
          currentOrder: [1, 2, 1],
          dailyTodoIds: [1, 2],
        ),
        [1, 2],
      );
    });

    test('deduplicates dailyTodoIds (second occurrence ignored)', () {
      expect(
        DailyTaskOrderController.normalizeOrder(
          currentOrder: [],
          dailyTodoIds: [1, 2, 1],
        ),
        [1, 2],
      );
    });

    test('all currentOrder ids valid and complete', () {
      expect(
        DailyTaskOrderController.normalizeOrder(
          currentOrder: [3, 1, 2],
          dailyTodoIds: [1, 2, 3],
        ),
        [3, 1, 2],
      );
    });
  });

  group('mergeReorderedSubset', () {
    test('empty subset returns normalized current order', () {
      expect(
        DailyTaskOrderController.mergeReorderedSubset(
          currentOrder: [1, 2, 3],
          reorderedSubsetIds: [],
          dailyTodoIds: [1, 2, 3],
        ),
        [1, 2, 3],
      );
    });

    test('subset of one item: order unchanged', () {
      expect(
        DailyTaskOrderController.mergeReorderedSubset(
          currentOrder: [1, 2, 3],
          reorderedSubsetIds: [2],
          dailyTodoIds: [1, 2, 3],
        ),
        [1, 2, 3],
      );
    });

    test('reordering a subset swaps relative positions', () {
      // Original: 1, 2, 3; reorder subset [2,3] → [3,2]
      // Result: 1 stays, then 3, then 2
      expect(
        DailyTaskOrderController.mergeReorderedSubset(
          currentOrder: [1, 2, 3],
          reorderedSubsetIds: [3, 2],
          dailyTodoIds: [1, 2, 3],
        ),
        [1, 3, 2],
      );
    });

    test('all items reordered: new order is the subset', () {
      expect(
        DailyTaskOrderController.mergeReorderedSubset(
          currentOrder: [1, 2, 3],
          reorderedSubsetIds: [3, 1, 2],
          dailyTodoIds: [1, 2, 3],
        ),
        [3, 1, 2],
      );
    });

    test('subset items not in currentOrder are appended', () {
      // 4 is new; when 2 (subset item) is encountered, 4 from reordered takes its slot;
      // 3 stays; 2 is appended by final normalization
      expect(
        DailyTaskOrderController.mergeReorderedSubset(
          currentOrder: [1, 2, 3],
          reorderedSubsetIds: [4, 2],
          dailyTodoIds: [1, 2, 3, 4],
        ),
        [1, 4, 3, 2],
      );
    });

    test('subset items not in dailyTodoIds are filtered out by normalization', () {
      // 99 is not in dailyTodoIds; after merge, 99 is skipped in normalization
      // but 2 stays in its original position since the merge places it before 3
      expect(
        DailyTaskOrderController.mergeReorderedSubset(
          currentOrder: [1, 2, 3],
          reorderedSubsetIds: [2, 99],
          dailyTodoIds: [1, 2, 3],
        ),
        [1, 2, 3],
      );
    });

    test('non-subset items retain their relative positions', () {
      // [1, 2, 3, 4, 5], reorder subset [2, 5] → [5, 2]
      // Non-subset: 1, 3, 4 stay in place; subset positions get [5, 2]
      expect(
        DailyTaskOrderController.mergeReorderedSubset(
          currentOrder: [1, 2, 3, 4, 5],
          reorderedSubsetIds: [5, 2],
          dailyTodoIds: [1, 2, 3, 4, 5],
        ),
        [1, 5, 3, 4, 2],
      );
    });
  });

  group('hasSameOrder', () {
    test('same lists return true', () {
      expect(DailyTaskOrderController.hasSameOrder([1, 2, 3], [1, 2, 3]), true);
    });

    test('different lengths return false', () {
      expect(DailyTaskOrderController.hasSameOrder([1, 2], [1, 2, 3]), false);
    });

    test('same length, different elements return false', () {
      expect(DailyTaskOrderController.hasSameOrder([1, 2, 3], [1, 3, 2]), false);
    });

    test('empty lists return true', () {
      expect(DailyTaskOrderController.hasSameOrder([], []), true);
    });
  });
}
