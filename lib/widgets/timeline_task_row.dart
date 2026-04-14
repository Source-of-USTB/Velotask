import 'package:flutter/material.dart';
import 'package:velotask/models/todo.dart';
import 'package:velotask/theme/app_theme.dart';

class TimelineTaskRow extends StatelessWidget {
  final Todo todo;
  final DateTime today;
  final int daysToShow;
  final double dayWidth;

  const TimelineTaskRow({
    super.key,
    required this.todo,
    required this.today,
    required this.daysToShow,
    required this.dayWidth,
  });

  @override
  Widget build(BuildContext context) {
    return todo.taskType == TaskType.deadline
        ? _buildDeadlineRow(context)
        : _buildTaskRow(context);
  }

  Widget _buildDeadlineRow(BuildContext context) {
    final theme = Theme.of(context);
    final totalWidth = dayWidth * daysToShow;

    final ddlDate = todo.ddl;
    if (ddlDate == null) return const SizedBox.shrink();

    final normalized = DateTime(ddlDate.year, ddlDate.month, ddlDate.day);
    final offsetDays = normalized.difference(today).inDays;

    // Center the marker on the day column
    final centerX = (offsetDays + 0.5) * dayWidth;

    if (centerX < 0 || centerX > totalWidth) return const SizedBox.shrink();

    final accentColor = _getImportanceColor(todo.importance);

    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 8),
      child: Stack(
        children: [
          // Grid lines
          Row(
            children: List.generate(daysToShow, (index) {
              return Container(
                width: dayWidth,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
              );
            }),
          ),
          // Deadline vertical marker
          Positioned(
            left: centerX - 1,
            top: 8,
            bottom: 8,
            width: 2,
            child: Container(color: accentColor),
          ),
          // Diamond icon at top
          Positioned(
            left: centerX - 6,
            top: 4,
            child: Transform.rotate(
              angle: 0.785398, // 45 degrees
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Task label beside the marker
          Positioned(
            left: centerX + 6,
            top: 12,
            right: 4,
            height: 36,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                todo.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.headerStyle(context).copyWith(
                  color: theme.colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskRow(BuildContext context) {
    final theme = Theme.of(context);
    final totalWidth = dayWidth * daysToShow;

    final start = todo.startDate ?? todo.createdAt ?? today;
    final end = todo.ddl ?? start;

    // Normalize
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);

    // Calculate position
    int startOffsetDays = startDate.difference(today).inDays;
    int durationDays = endDate.difference(startDate).inDays + 1;

    // Clip to view
    double left = startOffsetDays * dayWidth;
    double width = durationDays * dayWidth;

    if (left < 0) {
      width += left;
      left = 0;
    }

    if (left + width > totalWidth) {
      width = totalWidth - left;
    }

    if (width <= 0) return const SizedBox.shrink();

    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 8),
      child: Stack(
        children: [
          // Grid lines
          Row(
            children: List.generate(daysToShow, (index) {
              return Container(
                width: dayWidth,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
              );
            }),
          ),
          // Task Bar
          Positioned(
            left: left + 2,
            top: 12,
            width: width - 4,
            height: 36,
            child: Container(
              decoration: BoxDecoration(
                color: _getImportanceColor(
                  todo.importance,
                ).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border(
                  left: BorderSide(
                    color: _getImportanceColor(todo.importance),
                    width: 3,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.centerLeft,
              child: Text(
                todo.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.captionStrongStyle(
                  context,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getImportanceColor(int importance) {
    switch (importance) {
      case 2:
        return AppTheme.highPriority;
      case 0:
        return AppTheme.lowPriority;
      default:
        return AppTheme.mediumPriority;
    }
  }
}
