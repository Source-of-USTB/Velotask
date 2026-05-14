import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:velotask/services/color_config_manager.dart';

class TimelineHeader extends StatelessWidget {
  static const double monthRowHeight = 34.0;
  static const double dayRowHeight = 34.0;
  static const double height = monthRowHeight + dayRowHeight;

  final DateTime chartStart;
  final int daysToShow;
  final double dayWidth;
  final DateTime now;

  const TimelineHeader({
    super.key,
    required this.chartStart,
    required this.daysToShow,
    required this.dayWidth,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final p = ColorConfigManager.instance.activePreset!;
    final b = Theme.of(context).brightness;

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
            now: now,
            bgColor: p.colorByKey('ganttHeaderBackground', b),
            weekendColor: p.colorByKey('ganttHeaderWeekendBg', b),
            dividerColor: p.colorByKey('ganttHeaderDivider', b),
            textColor: p.colorByKey('ganttHeaderText', b),
            mutedColor: p.colorByKey('ganttHeaderWeekendText', b),
            todayColor: p.colorByKey('ganttHeaderTodayText', b),
            todayBg: p.colorByKey('ganttHeaderTodayBg', b),
            nowColor: p.colorByKey('ganttNowLine', b),
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
  final DateTime now;
  final Color bgColor;
  final Color weekendColor;
  final Color dividerColor;
  final Color textColor;
  final Color mutedColor;
  final Color todayColor;
  final Color todayBg;
  final Color nowColor;

  static const double _monthRowH = TimelineHeader.monthRowHeight;
  static const double _dayRowH = TimelineHeader.dayRowHeight;

  const _HeaderPainter({
    required this.chartStart,
    required this.daysToShow,
    required this.dayWidth,
    required this.today,
    required this.now,
    required this.bgColor,
    required this.weekendColor,
    required this.dividerColor,
    required this.textColor,
    required this.mutedColor,
    required this.todayColor,
    required this.todayBg,
    required this.nowColor,
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

      // 周末背景
      if (isWeekend) {
        canvas.drawRect(
          Rect.fromLTWH(x, 0, dayWidth, size.height),
          Paint()..color = weekendColor,
        );
      }

      // 日期行
      if (isToday) {
        canvas.drawRect(
          Rect.fromLTWH(x, _monthRowH, dayWidth, _dayRowH),
          Paint()..color = todayBg,
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

    // 当前时间红线
    final nowX = now.difference(chartStart).inMinutes / 1440.0 * dayWidth;
    if (nowX >= 0 && nowX <= size.width) {
      canvas.drawLine(
        Offset(nowX, 0),
        Offset(nowX, size.height),
        Paint()
          ..color = nowColor
          ..strokeWidth = 2,
      );
    }
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
      old.now != now ||
      old.bgColor != bgColor ||
      old.weekendColor != weekendColor ||
      old.dividerColor != dividerColor ||
      old.textColor != textColor ||
      old.mutedColor != mutedColor ||
      old.todayColor != todayColor ||
      old.todayBg != todayBg ||
      old.nowColor != nowColor;
}
