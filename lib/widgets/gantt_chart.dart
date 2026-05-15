import 'package:flutter/material.dart';
import 'package:velotask/models/todo.dart';
import 'package:velotask/services/color_config_manager.dart';
import 'package:velotask/widgets/timeline_header.dart';
import 'package:velotask/widgets/timeline_layout.dart';
import 'package:velotask/widgets/timeline_task_row.dart';

class GanttChart extends StatelessWidget {
  final List<Todo> tasks;
  final void Function(Todo task)? onTaskDoubleTap;
  final ScrollController headerCtrl;
  final ScrollController bodyCtrl;
  final DateTime chartStart;
  final int totalDays;
  final double dayWidth;
  final double totalWidth;
  final DateTime now;

  const GanttChart({
    super.key,
    required this.tasks,
    required this.headerCtrl,
    required this.bodyCtrl,
    required this.chartStart,
    required this.totalDays,
    required this.dayWidth,
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
    // Month lines
    final monthPaint = Paint()
      ..color = monthColor
      ..strokeWidth = 4.0;

    final endDate = chartStart.add(Duration(days: totalDays));
    var monthCursor = DateTime(chartStart.year, chartStart.month, 1);
    while (!monthCursor.isAfter(endDate)) {
      if (!monthCursor.isBefore(chartStart)) {
        final x = monthCursor.difference(chartStart).inDays * dayWidth;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), monthPaint);
      }
      monthCursor = monthCursor.month == 12
          ? DateTime(monthCursor.year + 1, 1, 1)
          : DateTime(monthCursor.year, monthCursor.month + 1, 1);
    }

    // Week lines — step by 7 days
    final weekPaint = Paint()
      ..color = weekColor
      ..strokeWidth = 4;

    var weekCursor = chartStart;
    while (weekCursor.weekday != DateTime.monday) {
      weekCursor = weekCursor.add(const Duration(days: 1));
    }
    while (weekCursor.isBefore(endDate)) {
      final x = weekCursor.difference(chartStart).inDays * dayWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), weekPaint);
      weekCursor = weekCursor.add(const Duration(days: 7));
    }

    // Day boundary lines (2x+)
    if (dayWidth >= 120) {
      final dayPaint = Paint()
        ..color = weekColor.withValues(alpha: 0.55)
        ..strokeWidth = 2;
      for (double x = 0; x <= size.width + 0.5; x += dayWidth) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), dayPaint);
      }
    }

    // Noon lines (2x–4x)
    if (dayWidth >= 120 && dayWidth < 480) {
      final noonPaint = Paint()
        ..color = weekColor.withValues(alpha: 0.25)
        ..strokeWidth = 1;
      for (double x = dayWidth / 2; x < size.width; x += dayWidth) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), noonPaint);
      }
    }

    // Hour lines (8x+)
    if (dayWidth >= 480) {
      final hourPx = dayWidth / 24;
      final int hourStep;
      if (hourPx >= 70) {
        hourStep = 2;
      } else if (hourPx >= 35) {
        hourStep = 3;
      } else {
        hourStep = 6;
      }
      final stepPx = hourStep * hourPx;
      final hourPaint = Paint()
        ..color = weekColor.withValues(alpha: 0.2)
        ..strokeWidth = 1;

      for (double x = stepPx; x < size.width; x += stepPx) {
        final dayX = (x / dayWidth).round() * dayWidth;
        if ((x - dayX).abs() > 0.5) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), hourPaint);
        }
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
