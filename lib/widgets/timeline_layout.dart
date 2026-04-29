import 'package:flutter/widgets.dart';

/// 甘特图布局常量，通过 InheritedWidget 下传，避免逐层参数透传
class TimelineLayout extends InheritedWidget {
  final DateTime chartStart;
  final int totalDays;
  final double dayWidth;
  final double totalWidth;

  const TimelineLayout({
    super.key,
    required this.chartStart,
    required this.totalDays,
    required this.dayWidth,
    required this.totalWidth,
    required super.child,
  });

  static TimelineLayout of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TimelineLayout>()!;
  }

  @override
  bool updateShouldNotify(TimelineLayout old) =>
      old.chartStart != chartStart ||
      old.totalDays != totalDays ||
      old.dayWidth != dayWidth ||
      old.totalWidth != totalWidth;
}
