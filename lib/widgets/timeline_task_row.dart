import 'package:flutter/material.dart';
import 'package:velotask/models/todo.dart';
import 'package:velotask/theme/app_theme.dart';
import 'package:velotask/widgets/timeline_layout.dart';

class TimelineTaskRow extends StatelessWidget {
  final Todo todo;
  final void Function(Todo)? onDoubleTap;

  static const double rowHeight = 52.0;
  static const double _barHeight = 34.0;
  static const double _barPadding = (rowHeight - _barHeight) / 2;

  const TimelineTaskRow({
    super.key,
    required this.todo,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: todo.taskType == TaskType.deadline
          ? _buildDeadlineRow(context)
          : _buildRangeRow(context),
    );
  }

  Color _getTaskColor(BuildContext context) {
    switch (todo.importance) {
      case 2:
        return AppTheme.highPriority;
      case 0:
        return AppTheme.lowPriority;
      default:
        return AppTheme.mediumPriority;
    }
  }

  Widget _buildDeadlineRow(BuildContext context) {
    final layout = TimelineLayout.of(context);
    final theme = Theme.of(context);
    final color = _getTaskColor(context);
    const minutesPerDay = 1440.0;

    // Todo.ddl 对应 endDate
    final ddl = todo.ddl;
    if (ddl == null) {
      return SizedBox(
        height: rowHeight,
        width: layout.totalWidth,
      );
    }

    final endMinutes = ddl.difference(layout.chartStart).inMinutes;
    final x = (endMinutes / minutesPerDay * layout.dayWidth).clamp(0.0, layout.totalWidth);

    return SizedBox(
      height: rowHeight,
      width: layout.totalWidth,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // 行分隔线
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          // 菱形标记 + 标题
          Positioned(
            left: x - _barHeight / 2,
            top: _barPadding,
            child: GestureDetector(
              onDoubleTap: () => onDoubleTap?.call(todo),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.rotate(
                      angle: 0.785, // 45°
                      child: Container(
                        width: _barHeight * 0.6,
                        height: _barHeight * 0.6,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      todo.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeRow(BuildContext context) {
    final layout = TimelineLayout.of(context);
    final theme = Theme.of(context);
    final color = _getTaskColor(context);
    const minutesPerDay = 1440.0;

    // Todo.startDate 对应 startDate, Todo.ddl 对应 endDate
    final start = todo.startDate ?? todo.createdAt;
    final end = todo.ddl;
    if (start == null || end == null) {
      return SizedBox(
        height: rowHeight,
        width: layout.totalWidth,
      );
    }

    final startMinutes = start.difference(layout.chartStart).inMinutes;
    final left = (startMinutes / minutesPerDay * layout.dayWidth).clamp(0.0, layout.totalWidth);
    final durationMinutes = end.difference(start).inMinutes;
    final minWidth = layout.dayWidth / minutesPerDay;
    final barWidth = (durationMinutes / minutesPerDay * layout.dayWidth).clamp(
      minWidth,
      layout.totalWidth - left,
    );

    return SizedBox(
      height: rowHeight,
      width: layout.totalWidth,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // 行分隔线
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),

          // 任务条
          Positioned(
            left: left,
            top: _barPadding,
            width: barWidth,
            height: _barHeight,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: color,
                borderRadius: BorderRadius.circular(8),
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                  radius: 150,
                  hoverColor: Colors.white.withValues(alpha: 0.15),
                  mouseCursor: SystemMouseCursors.click,
                  onDoubleTap: () => onDoubleTap?.call(todo),
                  highlightColor: Colors.white.withValues(alpha: 0.1),
                  splashColor: Colors.white.withValues(alpha: 0.2),
                  child: _TaskBar(todo: todo),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskBar extends StatelessWidget {
  final Todo todo;

  const _TaskBar({required this.todo});

  @override
  Widget build(BuildContext context) {
    final isDone = todo.isCompleted;
    return Opacity(
      opacity: isDone ? 0.45 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            if (isDone) ...[
              const Icon(Icons.check, color: Colors.white, size: 14),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                todo.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
