import 'package:shared_preferences/shared_preferences.dart';

class DailyTaskOrderController {
  static const String _orderKey = 'daily_task_order_ids';

  static Future<List<int>> loadOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_orderKey) ?? const [];
    return saved.map(int.tryParse).whereType<int>().toList();
  }

  static Future<void> saveOrder(List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _orderKey,
      ids.map((id) => id.toString()).toList(),
    );
  }

  static List<int> normalizeOrder({
    required List<int> currentOrder,
    required Iterable<int> dailyTodoIds,
  }) {
    final dailyIds = dailyTodoIds.toList();
    final dailyIdSet = dailyIds.toSet();
    final result = <int>[];
    final seen = <int>{};

    for (final id in currentOrder) {
      if (dailyIdSet.contains(id) && seen.add(id)) {
        result.add(id);
      }
    }

    for (final id in dailyIds) {
      if (seen.add(id)) {
        result.add(id);
      }
    }

    return result;
  }

  static List<int> mergeReorderedSubset({
    required List<int> currentOrder,
    required List<int> reorderedSubsetIds,
    required Iterable<int> dailyTodoIds,
  }) {
    final normalized = normalizeOrder(
      currentOrder: currentOrder,
      dailyTodoIds: dailyTodoIds,
    );
    final subset = reorderedSubsetIds.toSet();
    final result = <int>[];
    var subsetIndex = 0;

    for (final id in normalized) {
      if (!subset.contains(id)) {
        result.add(id);
        continue;
      }
      while (subsetIndex < reorderedSubsetIds.length) {
        final nextId = reorderedSubsetIds[subsetIndex++];
        if (subset.contains(nextId)) {
          result.add(nextId);
          break;
        }
      }
    }

    return normalizeOrder(currentOrder: result, dailyTodoIds: dailyTodoIds);
  }

  static bool hasSameOrder(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
