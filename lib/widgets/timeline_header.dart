import 'package:flutter/material.dart';
import 'package:velotask/theme/app_theme.dart';
import 'package:velotask/l10n/app_localizations.dart';

class TimelineHeader extends StatelessWidget {
  final DateTime today;
  final int daysToShow;
  final double dayWidth;

  const TimelineHeader({
    super.key,
    required this.today,
    required this.daysToShow,
    required this.dayWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: List.generate(daysToShow, (index) {
          final date = today.add(Duration(days: index));
          final isToday = index == 0;
          return SizedBox(
            width: dayWidth,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getWeekday(context, date.weekday).toUpperCase(),
                  style: AppTheme.headerStyle(context).copyWith(
                    fontSize: 10,
                    color: isToday ? theme.primaryColor : secondaryColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: isToday
                      ? BoxDecoration(
                          color: theme.primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        )
                      : null,
                  child: Text(
                    date.day.toString(),
                    style: AppTheme.headerStyle(context).copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isToday
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _getWeekday(BuildContext context, int weekday) {
    final l10n = AppLocalizations.of(context)!;
    switch (weekday) {
      case DateTime.monday:
        return l10n.shortWeekdayMon;
      case DateTime.tuesday:
        return l10n.shortWeekdayTue;
      case DateTime.wednesday:
        return l10n.shortWeekdayWed;
      case DateTime.thursday:
        return l10n.shortWeekdayThu;
      case DateTime.friday:
        return l10n.shortWeekdayFri;
      case DateTime.saturday:
        return l10n.shortWeekdaySat;
      case DateTime.sunday:
        return l10n.shortWeekdaySun;
      default:
        return '';
    }
  }
}
