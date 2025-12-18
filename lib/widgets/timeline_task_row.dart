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

    // Adjust for out of bounds
    if (left < 0) {
      width += left; // Reduce width by the amount clipped from left
      left = 0;
    }

    // Max width constraint
    if (left + width > totalWidth) {
      width = totalWidth - left;
    }

    // If completely out of view (should be filtered out, but safety check)
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
            left: left + 2, // Tighter padding
            top: 12,
            width: width - 4, // Tighter padding
            height: 36,
            child: Container(
              decoration: BoxDecoration(
                color: _getImportanceColor(
                  todo.importance,
                ).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4), // Sharper corners
                border: Border(
                  left: BorderSide(
                    color: _getImportanceColor(todo.importance),
                    width: 3, // Accent on the left
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
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
