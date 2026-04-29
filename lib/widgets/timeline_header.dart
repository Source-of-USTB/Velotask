import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimelineHeader extends StatelessWidget {
  static const double monthRowHeight = 34.0;
  static const double dayRowHeight = 34.0;
  static const double height = monthRowHeight + dayRowHeight;

  final DateTime chartStart;
  final int daysToShow;
  final double dayWidth;

  const TimelineHeader({
    super.key,
    required this.chartStart,
    required this.daysToShow,
    required this.dayWidth,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return RepaintBoundary(
      child: SizedBox(
        width: daysToShow * dayWidth,
        height: height,
        child: CustomPaint(
          painter: _HeaderPainter(
            chartStart: chartStart,
            daysToShow: daysToShow,
            dayWidth: dayWidth,
            today: DateTime.now(),
            bgColor: cs.surfaceContainerHighest,
            dividerColor: cs.outlineVariant,
            textColor: cs.onSurface,
            mutedColor: cs.onSurfaceVariant,
            todayColor: cs.primary,
          ),
        ),
      ),
    );
  }
}

class _HeaderPainter extends CustomPainter {
  final DateTime chartStart;
  final int daysToShow;
  final double dayWidth;
  final DateTime today;
  final Color bgColor;
  final Color dividerColor;
  final Color textColor;
  final Color mutedColor;
  final Color todayColor;

  static const double _monthRowH = TimelineHeader.monthRowHeight;
  static const double _dayRowH = TimelineHeader.dayRowHeight;

  const _HeaderPainter({
    required this.chartStart,
    required this.daysToShow,
    required this.dayWidth,
    required this.today,
    required this.bgColor,
    required this.dividerColor,
    required this.textColor,
    required this.mutedColor,
    required this.todayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 背景
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = bgColor,
    );

    // 样式
    final thinLine = Paint()
      ..color = dividerColor
      ..strokeWidth = 3.0;
    final normalStyle = TextStyle(color: mutedColor, fontSize: 14);
    final boldStyle = TextStyle(
      color: textColor,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );
    final todayStyle = TextStyle(
      color: todayColor,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    );
    final monthStyle = TextStyle(
      color: textColor,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );

    String? curMonth;
    double monthStartX = 0;
    final fmt = DateFormat('yyyy.MM');

    for (int i = 0; i < daysToShow; i++) {
      final date = chartStart.add(Duration(days: i));
      final x = i * dayWidth;
      final isToday = _isSameDay(date, today);
      final isWeekend =
          date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

      // 月份行
      final monthLabel = fmt.format(date);
      if (monthLabel != curMonth) {
        if (curMonth != null) {
          _drawText(canvas, curMonth, monthStartX + 4, 3, monthStyle);
        }
        curMonth = monthLabel;
        monthStartX = x;
        canvas.drawLine(Offset(x, 0), Offset(x, _monthRowH), thinLine);
      }

      // 日期行
      if (isToday) {
        canvas.drawRect(
          Rect.fromLTWH(x, _monthRowH, dayWidth, _dayRowH),
          Paint()..color = todayColor.withValues(alpha: 0.12),
        );
      }

      final style = isToday
          ? todayStyle
          : isWeekend
          ? normalStyle
          : boldStyle;
      _drawCenteredText(
        canvas,
        date.day.toString(),
        x,
        x + dayWidth,
        _monthRowH + 6,
        style,
      );

      canvas.drawLine(Offset(x, _monthRowH), Offset(x, size.height), thinLine);
    }

    if (curMonth != null) {
      _drawText(canvas, curMonth, monthStartX + 4, 3, monthStyle);
    }

    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      Paint()
        ..color = dividerColor
        ..strokeWidth = 1,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _drawText(
    Canvas canvas,
    String text,
    double x,
    double y,
    TextStyle style,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x, y));
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    double startX,
    double endX,
    double y,
    TextStyle style,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    final offsetX = startX + (endX - startX - tp.width) / 2;
    tp.paint(canvas, Offset(offsetX, y));
  }

  @override
  bool shouldRepaint(_HeaderPainter old) =>
      old.chartStart != chartStart ||
      old.daysToShow != daysToShow ||
      old.dayWidth != dayWidth ||
      old.bgColor != bgColor ||
      old.dividerColor != dividerColor ||
      old.textColor != textColor ||
      old.mutedColor != mutedColor ||
      old.todayColor != todayColor;
}
