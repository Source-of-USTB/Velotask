import 'package:flutter/material.dart';
import 'package:velotask/models/todo.dart';
import 'package:velotask/services/color_config_manager.dart';
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
    final p = ColorConfigManager.instance.activePreset!;
    final b = Theme.of(context).brightness;
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
                          weekendColor: p.colorByKey('ganttWeekendStripe', b),
                        ),
                        child: CustomPaint(
                          painter: _GridLinePainter(
                            chartStart: chartStart,
                            totalDays: totalDays,
                            dayWidth: dayWidth,
                            monthColor: p.colorByKey('ganttMonthGridLine', b),
                            weekColor: p.colorByKey('ganttWeekGridLine', b),
                          ),
                          foregroundPainter: _NowLinePainter(
                            chartStart: chartStart,
                            now: now,
                            dayWidth: dayWidth,
                            color: p.colorByKey('ganttNowLine', b),
                          ),
                          child: ListView.builder(
                            itemCount: tasks.length,
                            itemExtent: TimelineTaskRow.rowHeight,
                            itemBuilder: (_, i) => TimelineTaskRow(
                              todo: tasks[i],
                              onDoubleTap: onTaskDoubleTap,
                            ),
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

class _GridLinePainter extends CustomPainter {
  final DateTime chartStart;
  final int totalDays;
  final double dayWidth;
  final Color monthColor;
  final Color weekColor;

  const _GridLinePainter({
    required this.chartStart,
    required this.totalDays,
    required this.dayWidth,
    required this.monthColor,
    required this.weekColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Month lines first (below), thicker so overlap with week lines is visible
    final monthPaint = Paint()
      ..color = monthColor
      ..strokeWidth = 4.0;

    var monthCursor = DateTime(chartStart.year, chartStart.month, 1);
    final endDate = chartStart.add(Duration(days: totalDays));
    while (!monthCursor.isAfter(endDate)) {
      if (!monthCursor.isBefore(chartStart)) {
        final dayOffset = monthCursor.difference(chartStart).inDays;
        final x = dayOffset * dayWidth;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), monthPaint);
      }
      if (monthCursor.month == 12) {
        monthCursor = DateTime(monthCursor.year + 1, 1, 1);
      } else {
        monthCursor = DateTime(monthCursor.year, monthCursor.month + 1, 1);
      }
    }

    // Week lines on top
    final weekPaint = Paint()
      ..color = weekColor
      ..strokeWidth = 4;

    for (int i = 0; i < totalDays; i++) {
      final date = chartStart.add(Duration(days: i));
      if (date.weekday == DateTime.monday) {
        final x = i * dayWidth;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), weekPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridLinePainter old) =>
      old.chartStart != chartStart ||
      old.totalDays != totalDays ||
      old.dayWidth != dayWidth ||
      old.monthColor != monthColor ||
      old.weekColor != weekColor;
}

class _NowLinePainter extends CustomPainter {
  final DateTime chartStart;
  final DateTime now;
  final double dayWidth;
  final Color color;

  const _NowLinePainter({
    required this.chartStart,
    required this.now,
    required this.dayWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final nowMinutes = now.difference(chartStart).inMinutes;
    final x = (nowMinutes / 1440.0 * dayWidth).clamp(0.0, size.width);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _NowLinePainter old) =>
      old.chartStart != chartStart ||
      old.now != now ||
      old.dayWidth != dayWidth ||
      old.color != color;
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
