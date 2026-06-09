import 'package:flutter/material.dart';
import 'package:velotask/l10n/app_localizations.dart';
import 'package:velotask/models/todo.dart';
import 'package:velotask/widgets/progress/progress_circle.dart';

class DailyProgressHeader extends StatelessWidget {
  final List<Todo> todos;

  const DailyProgressHeader({super.key, required this.todos});

  @override
  Widget build(BuildContext context) {
    final daily = todos.where((t) => t.taskType == TaskType.daily).toList();
    final done = daily.where((t) => t.isDone).length;
    final total = daily.length;
    final progress = total == 0 ? 1.0 : done / total;

    return ProgressCircle(
      progress: progress,
      showCelebration: total > 0 && done == total,
      label: AppLocalizations.of(context)!.dailyCompleted,
    );
  }
}
