import 'package:velotask/models/tag.dart';

/// Logical task type.
enum TaskType { task, deadline, daily }

/// How a todo's children should be presented.
enum TaskGroupMode { none, subtasks, parallel }

extension TaskGroupModeRules on TaskGroupMode {
  bool get requiresParent => this != TaskGroupMode.none;
}

/// Plain data class used throughout the UI.
/// The actual Drift table definition lives in database.dart (Todos table).
class Todo {
  static const String defaultParallelPlan = 'A';
  static const int maxParallelPlanLength = 32;

  final int id;

  String title;
  String description;
  bool isCompleted;
  DateTime? createdAt;
  DateTime? startDate;
  DateTime? ddl;
  DateTime? lastCompletedDate;
  int importance; // 0: Low, 1: Normal, 2: High
  TaskType taskType;
  double? estimatedEffortHours;
  int? parentTodoId;
  TaskGroupMode groupMode;
  String? parallelPlan;

  /// Tags associated with this todo (loaded alongside the todo).
  List<Tag> tags;

  Todo({
    this.id = 0,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.createdAt,
    this.startDate,
    this.ddl,
    this.lastCompletedDate,
    this.importance = 1,
    this.taskType = TaskType.task,
    List<Tag> tags = const [],
    this.estimatedEffortHours,
    this.parentTodoId,
    this.groupMode = TaskGroupMode.none,
    this.parallelPlan,
  }) : tags = List<Tag>.from(tags);

  Todo copyWith({
    int? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? ddl,
    DateTime? lastCompletedDate,
    int? importance,
    TaskType? taskType,
    List<Tag>? tags,
    double? estimatedEffortHours,
    Object? parentTodoId = _sentinel,
    TaskGroupMode? groupMode,
    Object? parallelPlan = _sentinel,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      ddl: ddl ?? this.ddl,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      importance: importance ?? this.importance,
      taskType: taskType ?? this.taskType,
      tags: tags ?? this.tags,
      estimatedEffortHours: estimatedEffortHours ?? this.estimatedEffortHours,
      parentTodoId: identical(parentTodoId, _sentinel)
          ? this.parentTodoId
          : parentTodoId as int?,
      groupMode: groupMode ?? this.groupMode,
      parallelPlan: identical(parallelPlan, _sentinel)
          ? this.parallelPlan
          : parallelPlan as String?,
    );
  }

  static String? normalizeParallelPlan(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  bool get hasParent => parentTodoId != null;

  bool get hasValidGrouping {
    if (groupMode.requiresParent) {
      if (parentTodoId == null || parentTodoId == id) {
        return false;
      }
    } else if (parentTodoId != null) {
      return false;
    }

    final normalizedPlan = normalizeParallelPlan(parallelPlan);
    if (groupMode == TaskGroupMode.parallel) {
      return normalizedPlan != null &&
          normalizedPlan.length <= maxParallelPlanLength;
    }
    return parallelPlan == null;
  }

  void validateGrouping() {
    if (!hasValidGrouping) {
      throw ArgumentError('Invalid todo grouping');
    }
  }

  bool get isDone {
    if (taskType != TaskType.daily) return isCompleted;
    if (lastCompletedDate == null) return false;
    final today = DateTime.now();
    return lastCompletedDate!.year == today.year &&
        lastCompletedDate!.month == today.month &&
        lastCompletedDate!.day == today.day;
  }
}

const Object _sentinel = Object();
