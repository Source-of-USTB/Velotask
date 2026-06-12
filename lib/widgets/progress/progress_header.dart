import 'package:flutter/material.dart';
import 'package:velotask/l10n/app_localizations.dart';
import 'package:velotask/models/todo.dart';
import 'package:velotask/widgets/progress/progress_circle.dart';

class ProgressHeader extends StatelessWidget {
  final List<Todo> todos;
  final double size;

  const ProgressHeader({super.key, required this.todos, this.size = 140});

  @override
  Widget build(BuildContext context) {
    final nonDaily = todos.where((t) => t.taskType != TaskType.daily).toList();
    final done = nonDaily.where((t) => t.isCompleted).length;
    final total = nonDaily.length;
    final progress = total == 0 ? 1.0 : done / total;

    return ProgressCircle(
      progress: progress,
      showCelebration: total > 0 && done == total,
      label: AppLocalizations.of(context)!.completed,
      size: size,
    );
  }
}
