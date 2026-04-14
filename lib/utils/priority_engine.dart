import 'dart:math' as math;

import 'package:velotask/models/todo.dart';

// TODO: 设计一个更好的优先级算法，考虑更多因素，比如任务之间的依赖关系、用户的习惯、历史完成情况等。
enum PriorityNotificationTier { none, low, medium, high }

enum UrgencyBand { relaxed, medium, high, impossible }

class PriorityEngine {
  const PriorityEngine._();

  static const double _alpha = 0.82;
  static const double _beta = 0.18;
  static const double _xScale = 50.4;
  static const double _xShape = 1.14;
  static const double _nearBoost = 0.45;
  static const double _nearScale = 6.0;
  static const double _urgencyCap = 1.2;
  static const double _overdueSlope = 0.15;
  static const double _focusRatio = 0.35;
  static const double _noDeadlineHours = 24 * 21;

  static final RegExp _effortRegex = RegExp(
    r'(?:^|\s)(\d+(?:\.\d+)?)\s*(h|hr|hrs|hour|hours|小时)',
    caseSensitive: false,
  );

  static double score(Todo todo, {DateTime? now}) {
    return scoreWithContext(todo, allTodos: null, now: now);
  }

  static double scoreWithContext(
    Todo todo, {
    List<Todo>? allTodos,
    DateTime? now,
  }) {
    if (todo.isCompleted) {
      return -1;
    }

    final current = now ?? DateTime.now();
    final overloadMultiplier = _overloadMultiplier(
      sourceTodos: allTodos,
      now: current,
    );
    final urgencyValue = _urgencyWithOverload(
      todo,
      now: current,
      overloadMultiplier: overloadMultiplier,
    );
    final p = _priorityValue(todo.importance);

    return _alpha * urgencyValue + _beta * p;
  }

  static UrgencyBand urgencyBand(
    Todo todo, {
    List<Todo>? allTodos,
    DateTime? now,
  }) {
    if (todo.isCompleted) {
      return UrgencyBand.relaxed;
    }

    final u = urgency(todo, allTodos: allTodos, now: now);
    if (u >= 1) {
      return UrgencyBand.impossible;
    }
    if (u >= 0.7) {
      return UrgencyBand.high;
    }
    if (u >= 0.3) {
      return UrgencyBand.medium;
    }
    return UrgencyBand.relaxed;
  }

  static double urgency(Todo todo, {List<Todo>? allTodos, DateTime? now}) {
    if (todo.isCompleted) {
      return 0;
    }

    final current = now ?? DateTime.now();
    final overloadMultiplier = _overloadMultiplier(
      sourceTodos: allTodos,
      now: current,
    );

    return _urgencyWithOverload(
      todo,
      now: current,
      overloadMultiplier: overloadMultiplier,
    );
  }

  static double remainingHours(Todo todo, {DateTime? now}) {
    final raw = _rawRemainingHours(todo, now: now);
    if (raw <= 0) {
      return 0.25;
    }
    return raw;
  }

  static double _rawRemainingHours(Todo todo, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final ddl = todo.ddl;
    if (ddl == null) {
      return _noDeadlineHours;
    }
    return ddl.difference(current).inMinutes / 60.0;
  }

  static double estimatedEffortHours(Todo todo) {
    final storedEffort = todo.estimatedEffortHours;
    if (storedEffort != null && storedEffort > 0) {
      return storedEffort.clamp(0.25, 100.0);
    }

    final text = '${todo.title} ${todo.description}';
    final match = _effortRegex.firstMatch(text);
    if (match != null) {
      final parsed = double.tryParse(match.group(1) ?? '');
      if (parsed != null && parsed > 0) {
        return parsed.clamp(0.25, 100.0);
      }
    }

    return switch (todo.importance) {
      <= 0 => 1.5,
      1 => 3.0,
      _ => 5.0,
    };
  }

  static int compare(Todo a, Todo b, {DateTime? now, List<Todo>? allTodos}) {
    final current = now ?? DateTime.now();
    final source = allTodos;

    final sa = scoreWithContext(a, allTodos: source, now: current);
    final sb = scoreWithContext(b, allTodos: source, now: current);

    final scoreCompare = sb.compareTo(sa);
    if (scoreCompare != 0) {
      return scoreCompare;
    }

    final ua = urgency(a, allTodos: source, now: current);
    final ub = urgency(b, allTodos: source, now: current);
    final urgencyCompare = ub.compareTo(ua);
    if (urgencyCompare != 0) {
      return urgencyCompare;
    }

    final ddlA = a.ddl;
    final ddlB = b.ddl;
    if (ddlA != null && ddlB != null) {
      final ddlCompare = ddlA.compareTo(ddlB);
      if (ddlCompare != 0) {
        return ddlCompare;
      }
    } else if (ddlA != null) {
      return -1;
    } else if (ddlB != null) {
      return 1;
    }

    return a.id.compareTo(b.id);
  }

  static PriorityNotificationTier notificationTier(
    Todo todo, {
    DateTime? now,
    List<Todo>? allTodos,
  }) {
    if (todo.isCompleted) {
      return PriorityNotificationTier.none;
    }

    final band = urgencyBand(todo, allTodos: allTodos, now: now);
    return switch (band) {
      UrgencyBand.impossible => PriorityNotificationTier.high,
      UrgencyBand.high => PriorityNotificationTier.high,
      UrgencyBand.medium => PriorityNotificationTier.medium,
      UrgencyBand.relaxed =>
        _priorityValue(todo.importance) >= 2.5
            ? PriorityNotificationTier.low
            : PriorityNotificationTier.none,
    };
  }

  static double _priorityValue(int importance) {
    return switch (importance) {
      <= 0 => 1,
      1 => 2,
      _ => 3,
    };
  }

  static double _overloadMultiplier({
    required List<Todo>? sourceTodos,
    required DateTime now,
  }) {
    final todos = sourceTodos;
    if (todos == null || todos.isEmpty) {
      return 1.0;
    }

    var totalEffort = 0.0;
    var totalAvailable = 0.0;
    for (final todo in todos) {
      if (todo.isCompleted) {
        continue;
      }
      totalEffort += estimatedEffortHours(todo);
      totalAvailable += remainingHours(todo, now: now) * _focusRatio;
    }

    if (totalAvailable <= 0) {
      return 1.8;
    }

    final load = totalEffort / totalAvailable;
    if (load <= 1) {
      return 1.0;
    }

    final excess = load - 1;
    final boost = (excess * 0.8).clamp(0.0, 1.2);
    return 1.0 + boost;
  }

  static List<Todo> sortedTodos(List<Todo> todos, {DateTime? now}) {
    if (todos.length <= 1) {
      return List<Todo>.from(todos);
    }

    final current = now ?? DateTime.now();
    final copied = List<Todo>.from(todos);
    final overloadMultiplier = _overloadMultiplier(
      sourceTodos: copied,
      now: current,
    );

    final scoreByTodo = <Todo, double>{};
    final urgencyByTodo = <Todo, double>{};
    for (final todo in copied) {
      if (todo.isCompleted) {
        scoreByTodo[todo] = -1;
        urgencyByTodo[todo] = 0;
        continue;
      }
      final urgencyValue = _urgencyWithOverload(
        todo,
        now: current,
        overloadMultiplier: overloadMultiplier,
      );
      urgencyByTodo[todo] = urgencyValue;
      scoreByTodo[todo] =
          _alpha * urgencyValue + _beta * _priorityValue(todo.importance);
    }

    copied.sort((a, b) {
      final sa = scoreByTodo[a] ?? -1;
      final sb = scoreByTodo[b] ?? -1;

      final scoreCompare = sb.compareTo(sa);
      if (scoreCompare != 0) {
        return scoreCompare;
      }

      final ua = urgencyByTodo[a] ?? 0;
      final ub = urgencyByTodo[b] ?? 0;
      final urgencyCompare = ub.compareTo(ua);
      if (urgencyCompare != 0) {
        return urgencyCompare;
      }

      final ddlA = a.ddl;
      final ddlB = b.ddl;
      if (ddlA != null && ddlB != null) {
        final ddlCompare = ddlA.compareTo(ddlB);
        if (ddlCompare != 0) {
          return ddlCompare;
        }
      } else if (ddlA != null) {
        return -1;
      } else if (ddlB != null) {
        return 1;
      }

      return a.id.compareTo(b.id);
    });

    return copied;
  }

  static bool isTheoreticallyLate(Todo todo, {DateTime? now}) {
    if (todo.isCompleted) {
      return false;
    }
    return urgencyBand(todo, now: now) == UrgencyBand.impossible;
  }

  static bool isHighUrgency(Todo todo, {DateTime? now, List<Todo>? allTodos}) {
    if (todo.isCompleted) {
      return false;
    }
    final band = urgencyBand(todo, now: now, allTodos: allTodos);
    return band == UrgencyBand.high || band == UrgencyBand.impossible;
  }

  static double urgencyRatioV1(Todo todo, {DateTime? now}) {
    if (todo.isCompleted) {
      return 0;
    }
    final current = now ?? DateTime.now();
    final effort = estimatedEffortHours(todo);
    final remaining = remainingHours(todo, now: current);
    return effort / remaining;
  }

  static double urgencyRatioV2(
    Todo todo, {
    DateTime? now,
    List<Todo>? allTodos,
  }) {
    if (todo.isCompleted) {
      return 0;
    }
    final current = now ?? DateTime.now();
    final overloadMultiplier = _overloadMultiplier(
      sourceTodos: allTodos,
      now: current,
    );
    return _urgencyWithOverload(
      todo,
      now: current,
      overloadMultiplier: overloadMultiplier,
    );
  }

  static double _urgencyWithOverload(
    Todo todo, {
    required DateTime now,
    required double overloadMultiplier,
  }) {
    final effort = estimatedEffortHours(todo);
    final rawRemaining = _rawRemainingHours(todo, now: now);

    double baseUrgency;
    if (rawRemaining <= 0) {
      baseUrgency = 1 + _overdueSlope * (rawRemaining.abs() / effort);
    } else {
      final x = rawRemaining / effort;
      final logistic = 1 / (1 + math.pow(x / _xScale, _xShape));
      final nearPressure = 1 + _nearBoost * math.exp(-x / _nearScale);
      baseUrgency = (logistic * nearPressure).clamp(0.0, _urgencyCap);
    }

    return baseUrgency * overloadMultiplier;
  }
}
