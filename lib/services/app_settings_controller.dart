import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class TimelineRangeSettings {
  final int pastMonths;
  final int futureMonths;

  const TimelineRangeSettings({
    required this.pastMonths,
    required this.futureMonths,
  });
}

class AppSettingsController {
  static const int defaultTimelinePastMonths = 1;
  static const int defaultTimelineFutureMonths = 2;
  static const int maxTimelineMonths = 12;
  static const String _timelinePastMonthsKey = 'timeline_past_months';
  static const String _timelineFutureMonthsKey = 'timeline_future_months';

  static final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);
  static final localeNotifier = ValueNotifier<Locale?>(null);
  static final timelineRangeNotifier = ValueNotifier<TimelineRangeSettings>(
    const TimelineRangeSettings(
      pastMonths: defaultTimelinePastMonths,
      futureMonths: defaultTimelineFutureMonths,
    ),
  );

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final savedTheme = prefs.getString('theme_mode');
    if (savedTheme != null) {
      themeNotifier.value = ThemeMode.values.firstWhere(
        (e) => e.toString() == savedTheme,
        orElse: () => ThemeMode.system,
      );
    }

    final savedLocale = prefs.getString('locale');
    if (savedLocale != null) {
      localeNotifier.value = Locale(savedLocale);
    }

    final pastMonths = prefs.getInt(_timelinePastMonthsKey);
    final futureMonths = prefs.getInt(_timelineFutureMonthsKey);
    if (pastMonths != null &&
        futureMonths != null &&
        isValidTimelineRange(pastMonths, futureMonths)) {
      timelineRangeNotifier.value = TimelineRangeSettings(
        pastMonths: pastMonths,
        futureMonths: futureMonths,
      );
    } else {
      timelineRangeNotifier.value = const TimelineRangeSettings(
        pastMonths: defaultTimelinePastMonths,
        futureMonths: defaultTimelineFutureMonths,
      );
    }
  }

  static Future<void> setTheme(ThemeMode mode) async {
    themeNotifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.toString());
  }

  static Future<void> setLocale(Locale? locale) async {
    localeNotifier.value = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale != null) {
      await prefs.setString('locale', locale.languageCode);
    } else {
      await prefs.remove('locale');
    }
  }

  static bool isValidTimelineRange(int pastMonths, int futureMonths) {
    return pastMonths >= 0 &&
        pastMonths <= maxTimelineMonths &&
        futureMonths >= 0 &&
        futureMonths <= maxTimelineMonths;
  }

  static Future<void> setTimelineRange({
    required int pastMonths,
    required int futureMonths,
  }) async {
    if (!isValidTimelineRange(pastMonths, futureMonths)) {
      throw ArgumentError(
        'Timeline months must be between 0 and $maxTimelineMonths.',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_timelinePastMonthsKey, pastMonths);
    await prefs.setInt(_timelineFutureMonthsKey, futureMonths);
    timelineRangeNotifier.value = TimelineRangeSettings(
      pastMonths: pastMonths,
      futureMonths: futureMonths,
    );
  }
}
