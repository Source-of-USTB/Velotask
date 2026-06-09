import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsController {
  static final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);
  static final localeNotifier = ValueNotifier<Locale?>(null);

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
}
