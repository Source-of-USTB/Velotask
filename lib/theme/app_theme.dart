import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:velotask/services/color_config_manager.dart';

class AppTheme {
  static Color get primaryColor =>
      ColorConfigManager.instance.activeLightPreset?.primaryColor ??
      const Color(0xFF2C3E50);

  static Color get highPriority =>
      ColorConfigManager.instance.activeLightPreset?.highPriority ??
      const Color(0xFFFF3F34);
  static Color get mediumPriority =>
      ColorConfigManager.instance.activeLightPreset?.mediumPriority ??
      const Color(0xFFFFA801);
  static Color get lowPriority =>
      ColorConfigManager.instance.activeLightPreset?.lowPriority ??
      const Color(0xFF0BE881);
  static Color get errorColor =>
      ColorConfigManager.instance.activeLightPreset?.errorColor ??
      const Color(0xFFFF5E57);

  static TextStyle headerStyle(BuildContext context) {
    final locale = Localizations.localeOf(context);

    if (locale.languageCode == 'zh') {
      return GoogleFonts.notoSansSc(
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      );
    }

    return GoogleFonts.exo2(
      textStyle: const TextStyle(
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  static TextStyle bodyStyle(
    BuildContext context, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return GoogleFonts.notoSansSc(
      fontSize: fontSize ?? 14,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color ?? Theme.of(context).textTheme.bodyMedium?.color,
    );
  }

  static TextStyle pageTitleStyle(BuildContext context, {Color? color}) {
    return headerStyle(context).copyWith(
      fontSize: 24,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.8,
      color: color ?? Theme.of(context).primaryColor,
    );
  }

  static TextStyle sectionTitleStyle(BuildContext context, {Color? color}) {
    return headerStyle(context).copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.4,
      color: color ?? Theme.of(context).primaryColor,
    );
  }

  static TextStyle dialogTitleStyle(BuildContext context, {Color? color}) {
    return headerStyle(context).copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.4,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle bodyStrongStyle(BuildContext context, {Color? color}) {
    return bodyStyle(
      context,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static TextStyle bodyMediumStrongStyle(BuildContext context, {Color? color}) {
    return bodyStyle(
      context,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static TextStyle captionStrongStyle(BuildContext context, {Color? color}) {
    return bodyStyle(
      context,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static TextStyle valueDisplayStyle(BuildContext context, {Color? color}) {
    return headerStyle(context).copyWith(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      color: color ?? Theme.of(context).colorScheme.onSurface,
      height: 1,
    );
  }

  static TextStyle brandTitleStyle(BuildContext context, {Color? color}) {
    return headerStyle(context).copyWith(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      color: color ?? Theme.of(context).primaryColor,
    );
  }

  static TextStyle bodyMediumStyle(BuildContext context, {Color? color}) {
    return bodyStyle(
      context,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: color,
    );
  }

  static TextStyle smallMediumStyle(BuildContext context, {Color? color}) {
    return bodyStyle(
      context,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: color,
    );
  }

  static TextStyle smallRegularStyle(BuildContext context, {Color? color}) {
    return bodyStyle(
      context,
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: color,
    );
  }

  static TextStyle tinyBoldStyle(BuildContext context, {Color? color}) {
    return bodyStyle(
      context,
      fontSize: 10,
      fontWeight: FontWeight.bold,
      color: color,
    );
  }

  static TextStyle stampStyle(BuildContext context, {Color? color}) {
    return bodyStyle(
      context,
      fontSize: 10,
      fontWeight: FontWeight.w800,
      color: color,
    ).copyWith(letterSpacing: 0.8);
  }

  static TextStyle progressValueStyle(BuildContext context, {Color? color}) {
    return headerStyle(context).copyWith(
      fontSize: 56,
      fontWeight: FontWeight.w900,
      color: color ?? Theme.of(context).primaryColor,
      height: 1.0,
      letterSpacing: -2.0,
    );
  }

  static TextStyle progressSymbolStyle(BuildContext context, {Color? color}) {
    return headerStyle(context).copyWith(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      color: color ?? Theme.of(context).colorScheme.secondary,
    );
  }

  static TextStyle progressCaptionStyle(BuildContext context, {Color? color}) {
    return headerStyle(context).copyWith(
      fontSize: 11,
      letterSpacing: 3.0,
      fontWeight: FontWeight.bold,
      color: color ?? Theme.of(context).colorScheme.secondary,
    );
  }

  static TextStyle chipLabelStyle(
    BuildContext context, {
    required bool selected,
    Color? color,
  }) {
    return bodyStyle(
      context,
      fontSize: 13,
      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      color: color,
    );
  }

  static TextStyle selectableLabelStyle(
    BuildContext context, {
    required bool selected,
    Color? color,
  }) {
    return bodyStyle(
      context,
      fontSize: 14,
      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      color: color,
    );
  }

  static TextStyle accentBodyStyle(BuildContext context, {Color? color}) {
    return bodyStyle(
      context,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static TextStyle dateChipStyle(
    BuildContext context, {
    required bool urgent,
    Color? color,
  }) {
    return bodyStyle(
      context,
      fontSize: 12,
      fontWeight: urgent ? FontWeight.bold : FontWeight.w500,
      color: color,
    );
  }

  static TextStyle celebrationEmojiStyle(BuildContext context, {Color? color}) {
    return valueDisplayStyle(context, color: color).copyWith(fontSize: 26);
  }

  static TextStyle weekdayCapsStyle(BuildContext context, {Color? color}) {
    return captionStrongStyle(
      context,
      color: color,
    ).copyWith(letterSpacing: 1.0);
  }

  static ColorScheme _lightColorScheme() =>
      ColorConfigManager.instance.toColorScheme(Brightness.light);

  static ColorScheme _darkColorScheme() =>
      ColorConfigManager.instance.toColorScheme(Brightness.dark);

  static Color _lightPrimary() =>
      ColorConfigManager.instance.activeLightPreset?.primaryColor ??
      const Color(0xFF2C3E50);

  static Color _lightBg() =>
      ColorConfigManager.instance.activeLightPreset?.backgroundColor ??
      const Color(0xFFF5F6FA);

  static Color _lightSurface() =>
      ColorConfigManager.instance.activeLightPreset?.surfaceColor ?? Colors.white;

  static Color _darkPrimary() =>
      ColorConfigManager.instance.activeDarkPreset?.primaryColor ??
      const Color(0xFFECF0F1);

  static Color _darkBg() =>
      ColorConfigManager.instance.activeDarkPreset?.backgroundColor ??
      const Color(0xFF121212);

  static Color _darkSurface() =>
      ColorConfigManager.instance.activeDarkPreset?.surfaceColor ??
      const Color(0xFF1E1E1E);

  static Color _darkAccent() =>
      ColorConfigManager.instance.activeDarkPreset?.accentColor ??
      const Color(0xFF3498DB);

  static ThemeData get lightTheme {
    final primary = _lightPrimary();
    final surface = _lightSurface();
    final bg = _lightBg();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      textTheme: GoogleFonts.notoSansScTextTheme().copyWith(
        bodyLarge: GoogleFonts.notoSansSc(fontSize: 16),
        bodyMedium: GoogleFonts.notoSansSc(fontSize: 14),
        bodySmall: GoogleFonts.notoSansSc(fontSize: 12),
        titleLarge: GoogleFonts.notoSansSc(
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.notoSansSc(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: GoogleFonts.notoSansSc(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      primaryColor: primary,
      colorScheme: _lightColorScheme(),

      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: primary,
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: primary),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.grey.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1),
        ),
        contentPadding: const EdgeInsets.all(16),
        labelStyle: const TextStyle(color: Color(0xFF95A5A6)),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final primary = _darkPrimary();
    final surface = _darkSurface();
    final bg = _darkBg();
    final accent = _darkAccent();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      textTheme: GoogleFonts.notoSansScTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            bodyLarge: GoogleFonts.notoSansSc(fontSize: 16),
            bodyMedium: GoogleFonts.notoSansSc(fontSize: 14),
            bodySmall: GoogleFonts.notoSansSc(fontSize: 12),
            titleLarge: GoogleFonts.notoSansSc(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
            titleMedium: GoogleFonts.notoSansSc(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            titleSmall: GoogleFonts.notoSansSc(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
      primaryColor: primary,
      colorScheme: _darkColorScheme(),

      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: primary,
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: primary),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1),
        ),
        contentPadding: const EdgeInsets.all(16),
        labelStyle: const TextStyle(color: Color(0xFFB0BEC5)),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
