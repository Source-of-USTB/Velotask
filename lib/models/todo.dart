import 'package:velotask/models/tag.dart';

/// Logical task type.
enum TaskType { task, deadline }

/// Plain data class used throughout the UI.
/// The actual Drift table definition lives in database.dart (Todos table).
class Todo {
  final int id;
  String title;
  String description;
  bool isCompleted;
  DateTime? createdAt;
  DateTime? startDate;
  DateTime? ddl;
  int importance; // 0: Low, 1: Normal, 2: High
  TaskType taskType;

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
    this.importance = 1,
    this.taskType = TaskType.task,
    this.tags = const [],
  });

  Todo copyWith({
    int? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? ddl,
    int? importance,
    TaskType? taskType,
    List<Tag>? tags,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      ddl: ddl ?? this.ddl,
      importance: importance ?? this.importance,
      taskType: taskType ?? this.taskType,
      tags: tags ?? this.tags,
    );
  }
}
