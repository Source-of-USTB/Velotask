import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Velocity Palette (Deep Steel & Asphalt)
  static const Color primaryColor = Color(
    0xFF2C3E50,
  ); // Midnight Blue (Desaturated)
  static const Color secondaryColor = Color(0xFF95A5A6); // Concrete Grey
  static const Color backgroundColor = Color(0xFFF5F6FA); // Light Grey Tint
  static const Color surfaceColor = Colors.white;

  // Importance Colors (Vivid & Fast)
  static const Color highPriority = Color(0xFFFF3F34); // Racing Red
  static const Color mediumPriority = Color(0xFFFFA801); // Signal Orange
  static const Color lowPriority = Color(0xFF0BE881); // Neon Green
  static const Color errorColor = Color(0xFFFF5E57);

  // Dark Theme Colors
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);
  static const Color darkPrimaryColor = Color(0xFFECF0F1); // Light text/icons
  static const Color darkSecondaryColor = Color(0xFFB0BEC5);
  static const Color darkAccentColor = Color(0xFF3498DB);

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

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
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
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: primaryColor,
        onSecondary: Colors.white,
        surface: surfaceColor,
      ),

      // AppBar Style
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: primaryColor,
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: primaryColor),
      ),

      // FAB Style
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      // Card Style
      cardTheme: CardThemeData(
        color: surfaceColor,
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

      // Input Decoration
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
          borderSide: const BorderSide(color: primaryColor, width: 1),
        ),
        contentPadding: const EdgeInsets.all(16),
        labelStyle: const TextStyle(color: secondaryColor),
      ),

      // Dialog Style
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),

      // Button Styles
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
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
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: darkBackgroundColor,
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
      primaryColor: darkPrimaryColor,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimaryColor,
        onPrimary: darkSurfaceColor,
        secondary: darkSecondaryColor,
        onSecondary: darkSurfaceColor,
        surface: darkSurfaceColor,
      ),

      // AppBar Style
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackgroundColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: darkPrimaryColor,
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: darkPrimaryColor),
      ),

      // FAB Style
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: darkAccentColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      // Card Style
      cardTheme: CardThemeData(
        color: darkSurfaceColor,
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

      // Input Decoration
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
          borderSide: const BorderSide(color: darkAccentColor, width: 1),
        ),
        contentPadding: const EdgeInsets.all(16),
        labelStyle: const TextStyle(color: darkSecondaryColor),
      ),

      // Dialog Style
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),

      // Button Styles
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkAccentColor,
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
          foregroundColor: darkAccentColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
