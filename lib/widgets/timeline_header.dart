import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:velotask/services/color_config_manager.dart';

class TimelineHeader extends StatelessWidget {
  static const double rowHeight = 34.0;
  static const double height = rowHeight * 2;

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

  static const double _rowH = TimelineHeader.rowHeight;
  static const double _totalH = TimelineHeader.height;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = bgColor,
    );

    if (dayWidth < 30) {
      _paintWeekMode(canvas, size);
    } else if (dayWidth < 480) {
      _paintDayMode(canvas, size);
    } else {
      _paintHourMode(canvas, size);
    }

    // Bottom border
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      Paint()
        ..color = dividerColor
        ..strokeWidth = 1,
    );

    // Now line
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

  // ─── Week mode (dayWidth < 30, i.e. 0.25x) ──────────────────────────

  void _paintWeekMode(Canvas canvas, Size size) {
    final monthStyle = TextStyle(
      color: textColor,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );
    final weekStyle = TextStyle(
      color: textColor,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );
    final thinLine = Paint()
      ..color = dividerColor
      ..strokeWidth = 2;
    final monthFmt = DateFormat('yyyy.MM');
    final weekFmt = DateFormat('M/d');

    String? curMonth;
    double monthStartX = 0;

    for (int i = 0; i < daysToShow; i++) {
      final date = chartStart.add(Duration(days: i));
      final x = i * dayWidth;

      // Month label
      final monthLabel = monthFmt.format(date);
      if (monthLabel != curMonth) {
        if (curMonth != null) {
          _drawText(canvas, curMonth, monthStartX + 4, 3, monthStyle);
        }
        curMonth = monthLabel;
        monthStartX = x;
        canvas.drawLine(Offset(x, 0), Offset(x, _rowH), thinLine);
      }

      // Weekend bg
      if (_isWeekend(date)) {
        canvas.drawRect(
          Rect.fromLTWH(x, 0, dayWidth, _totalH),
          Paint()..color = weekendColor,
        );
      }

      // Week marker on Mondays
      if (date.weekday == DateTime.monday) {
        canvas.drawLine(Offset(x, _rowH), Offset(x, _totalH), thinLine);
        _drawCenteredText(
          canvas,
          weekFmt.format(date),
          x,
          x + dayWidth * 7,
          _rowH + 6,
          weekStyle,
        );
      }
    }

    if (curMonth != null) {
      _drawText(canvas, curMonth, monthStartX + 4, 3, monthStyle);
    }
  }

  // ─── Day mode (30 ≤ dayWidth < 480, i.e. 0.5x–4x) ──────────────────

  void _paintDayMode(Canvas canvas, Size size) {
    final thinLine = Paint()
      ..color = dividerColor
      ..strokeWidth = 3;
    final monthStyle = TextStyle(
      color: textColor,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );
    final dayStyle = TextStyle(
      color: textColor,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );
    final mutedDayStyle = TextStyle(color: mutedColor, fontSize: 14);
    final todayStyle = TextStyle(
      color: todayColor,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    );
    final monthFmt = DateFormat('yyyy.MM');

    final showWeekday = dayWidth >= 120; // 2x+
    final weekdayFmt = DateFormat('E');

    String? curMonth;
    double monthStartX = 0;

    for (int i = 0; i < daysToShow; i++) {
      final date = chartStart.add(Duration(days: i));
      final x = i * dayWidth;
      final isToday = _isSameDay(date, today);
      final isWeekend = _isWeekend(date);

      // Month label
      final monthLabel = monthFmt.format(date);
      if (monthLabel != curMonth) {
        if (curMonth != null) {
          _drawText(canvas, curMonth, monthStartX + 4, 3, monthStyle);
        }
        curMonth = monthLabel;
        monthStartX = x;
        canvas.drawLine(Offset(x, 0), Offset(x, _rowH), thinLine);
      }

      // Weekend bg
      if (isWeekend) {
        canvas.drawRect(
          Rect.fromLTWH(x, 0, dayWidth, _totalH),
          Paint()..color = weekendColor,
        );
      }

      // Today bg
      if (isToday) {
        canvas.drawRect(
          Rect.fromLTWH(x, _rowH, dayWidth, _rowH),
          Paint()..color = todayBg,
        );
      }

      final style = isToday
          ? todayStyle
          : (isWeekend ? mutedDayStyle : dayStyle);
      final label = showWeekday
          ? '${date.day} ${weekdayFmt.format(date)}'
          : date.day.toString();
      _drawCenteredText(canvas, label, x, x + dayWidth, _rowH + 6, style);

      canvas.drawLine(Offset(x, _rowH), Offset(x, _totalH), thinLine);

      // Noon divider (2x+)
      if (dayWidth >= 120) {
        final noonX = x + dayWidth / 2;
        canvas.drawLine(
          Offset(noonX, _rowH),
          Offset(noonX, _totalH),
          Paint()
            ..color = dividerColor.withValues(alpha: 0.2)
            ..strokeWidth = 1,
        );
      }
    }

    if (curMonth != null) {
      _drawText(canvas, curMonth, monthStartX + 4, 3, monthStyle);
    }
  }

  // ─── Hour mode (dayWidth ≥ 480, i.e. 8x–32x) ────────────────────────

  void _paintHourMode(Canvas canvas, Size size) {
    final thinLine = Paint()
      ..color = dividerColor
      ..strokeWidth = 3;
    final hourLine = Paint()
      ..color = dividerColor.withValues(alpha: 0.35)
      ..strokeWidth = 2;
    final dateStyle = TextStyle(
      color: textColor,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );
    final hourStyle = TextStyle(
      color: textColor,
      fontSize: 11,
      fontWeight: FontWeight.w500,
    );
    final todayDateStyle = TextStyle(
      color: todayColor,
      fontSize: 13,
      fontWeight: FontWeight.bold,
    );
    final dateFmt = DateFormat('M/d E');

    // Hour step based on available width
    final hourPx = dayWidth / 24;
    final int hourStep;
    if (hourPx >= 70) {
      hourStep = 2; // 32x: label every 2 hours
    } else if (hourPx >= 35) {
      hourStep = 3; // 16x: label every 3 hours
    } else {
      hourStep = 6; // 8x: label every 6 hours
    }

    for (int i = 0; i < daysToShow; i++) {
      final date = chartStart.add(Duration(days: i));
      final dayX = i * dayWidth;
      final isToday = _isSameDay(date, today);
      final isWeekend = _isWeekend(date);

      // Weekend bg
      if (isWeekend) {
        canvas.drawRect(
          Rect.fromLTWH(dayX, 0, dayWidth, _totalH),
          Paint()..color = weekendColor,
        );
      }

      // Row 1: Date label at day boundary
      canvas.drawLine(Offset(dayX, 0), Offset(dayX, _totalH), thinLine);
      if (isToday) {
        canvas.drawRect(
          Rect.fromLTWH(dayX, 0, dayWidth, _rowH),
          Paint()..color = todayBg,
        );
      }
      _drawText(
        canvas,
        dateFmt.format(date),
        dayX + 6,
        6,
        isToday ? todayDateStyle : dateStyle,
      );

      // Row 2: Hour labels
      for (int h = 0; h < 24; h += hourStep) {
        final hx = dayX + h * hourPx;
        if (h > 0) {
          canvas.drawLine(Offset(hx, _rowH), Offset(hx, _totalH), hourLine);
        }
        _drawCenteredText(
          canvas,
          '$h:00',
          hx,
          hx + hourStep * hourPx,
          _rowH + 8,
          hourStyle,
        );
      }
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isWeekend(DateTime d) =>
      d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;

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
