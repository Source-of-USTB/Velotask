import 'package:flutter/material.dart';
import 'package:velotask/models/todo.dart';
import 'package:velotask/widgets/timeline_header.dart';
import 'package:velotask/widgets/timeline_layout.dart';
import 'package:velotask/widgets/timeline_task_row.dart';

class GanttChart extends StatelessWidget {
  static const double dayWidth = 60.0;

  final List<Todo> tasks;
  final void Function(Todo task)? onTaskDoubleTap;
  final ScrollController headerCtrl;
  final ScrollController bodyCtrl;
  final DateTime chartStart;
  final int totalDays;
  final double totalWidth;
  final DateTime now;

  const GanttChart({
    super.key,
    required this.tasks,
    required this.headerCtrl,
    required this.bodyCtrl,
    required this.chartStart,
    required this.totalDays,
    required this.totalWidth,
    required this.now,
    this.onTaskDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return TimelineLayout(
      chartStart: chartStart,
      totalDays: totalDays,
      dayWidth: dayWidth,
      totalWidth: totalWidth,
      child: Column(
        children: [
          SingleChildScrollView(
            controller: headerCtrl,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: TimelineHeader(
              chartStart: chartStart,
              daysToShow: totalDays,
              dayWidth: dayWidth,
              now: now,
            ),
          ),
          Expanded(
            child: tasks.isEmpty
                ? const _EmptyState()
                : SingleChildScrollView(
                    controller: bodyCtrl,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: totalWidth,
                      child: CustomPaint(
                        painter: _WeekendStripePainter(
                          chartStart: chartStart,
                          totalDays: totalDays,
                          dayWidth: dayWidth,
                          weekendColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                        ),
                        child: ListView.builder(
                          itemCount: tasks.length,
                          itemExtent: TimelineTaskRow.rowHeight,
                          itemBuilder: (_, i) => TimelineTaskRow(
                            todo: tasks[i],
                            now: now,
                            onDoubleTap: onTaskDoubleTap,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _WeekendStripePainter extends CustomPainter {
  final DateTime chartStart;
  final int totalDays;
  final double dayWidth;
  final Color weekendColor;

  const _WeekendStripePainter({
    required this.chartStart,
    required this.totalDays,
    required this.dayWidth,
    required this.weekendColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = weekendColor;
    for (int i = 0; i < totalDays; i++) {
      final date = chartStart.add(Duration(days: i));
      if (date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday) {
        final x = i * dayWidth;
        canvas.drawRect(Rect.fromLTWH(x, 0, dayWidth, size.height), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WeekendStripePainter old) =>
      old.chartStart != chartStart ||
      old.totalDays != totalDays ||
      old.dayWidth != dayWidth ||
      old.weekendColor != weekendColor;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks yet\nTap + to add',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
    );
  }
}
