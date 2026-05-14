import 'dart:math';

import 'package:flutter/material.dart';

String _generateId() {
  final r = Random();
  final ms = DateTime.now().microsecondsSinceEpoch;
  return '${ms.toRadixString(36)}_${r.nextInt(99999).toString().padLeft(5, '0')}';
}

const _allKeys = [
  'ganttMonthGridLine','ganttWeekGridLine','ganttRowDivider','ganttWeekendStripe',
  'ganttNowLine','ganttHeaderBackground','ganttHeaderWeekendBg','ganttHeaderDivider',
  'ganttHeaderText','ganttHeaderWeekendText','ganttHeaderTodayText','ganttHeaderTodayBg',
  'ganttDeadlineTaskFill','ganttRangeTaskHigh','ganttRangeTaskMedium','ganttRangeTaskLow',
  'ganttRangeTaskDefault','ganttTaskText',
  'homePageBackground','homeCardBackground','homeCardBorder',
  'homeProgressValue','homeProgressSymbol','homeProgressCaption',
  'homeTitleText','homeBodyText',
  'commonFabBackground','commonFabIcon','commonButtonBackground','commonButtonText',
  'commonInputFill','commonInputLabel','commonInputText','commonInputBorder',
  'commonAppBarBackground','commonAppBarTitle','commonErrorText','commonDivider',
];

Color _def(String key, Brightness b) {
  final dark = b == Brightness.dark;
  // Primary: #3570E5(L) / #5B96F7(D) — same blue family
  const primaryL = Color(0xFF3570E5);
  const primaryD = Color(0xFF5B96F7);
  // Surface hierarchy
  const surfPageL = Color(0xFFF4F6FA);
  const surfCardL = Color(0xFFFFFFFF);
  const surfFillL = Color(0xFFF0F2F6);
  const surfHeaderL = Color(0xFFECEEF4);
  const surfPageD = Color(0xFF0F121A);
  const surfCardD = Color(0xFF171B24);
  const surfFillD = Color(0xFF1D2230);
  const surfHeaderD = Color(0xFF141822);
  // Grid / divider
  const gridMajorL = Color(0xFFD0D5E0);
  const gridMajorD = Color(0xFF383E4B);
  const gridMinorAlphaL = 0x60;
  const gridMinorAlphaD = 0x40;
  const gridRowAlphaL = 0x44;
  const gridRowAlphaD = 0x33;
  // Weekend
  const weekendL = Color(0xFFEEF1F7);
  const weekendD = Color(0xFF11161E);
  // Text
  const textPriL = Color(0xFF1A1D25);
  const textSecL = Color(0xFF6B7182);
  const textPriD = Color(0xFFE3E8F2);
  const textSecD = Color(0xFF9098AB);
  // Semantic task fills (same both themes, white text on top)
  const taskHigh = Color(0xFFE53935);
  const taskMid = Color(0xFFF59300);
  const taskLow = Color(0xFF3FA34B);
  const taskDefault = Color(0xFF5C7A8A);
  // Now / deadline
  const nowRed = Color(0xFFFF453A);

  switch (key) {
    // ── Gantt Grid ──
    case 'ganttMonthGridLine': return dark ? gridMajorD : gridMajorL;
    case 'ganttWeekGridLine': return dark ? gridMajorD.withAlpha(gridMinorAlphaD) : gridMajorL.withAlpha(gridMinorAlphaL);
    case 'ganttRowDivider': return dark ? gridMajorD.withAlpha(gridRowAlphaD) : gridMajorL.withAlpha(gridRowAlphaL);
    case 'ganttWeekendStripe': return dark ? weekendD : weekendL;
    // ── Gantt Markers ──
    case 'ganttNowLine': return nowRed;
    case 'ganttDeadlineTaskFill': return nowRed;
    // ── Gantt Header ──
    case 'ganttHeaderBackground': return dark ? surfHeaderD : surfHeaderL;
    case 'ganttHeaderWeekendBg': return dark ? weekendD : weekendL;
    case 'ganttHeaderDivider': return dark ? gridMajorD : gridMajorL;
    case 'ganttHeaderText': return dark ? textPriD : textPriL;
    case 'ganttHeaderWeekendText': return dark ? textSecD : textSecL;
    case 'ganttHeaderTodayText': return dark ? primaryD : primaryL;
    case 'ganttHeaderTodayBg': return dark ? primaryD.withAlpha(0x1A) : primaryL.withAlpha(0x1A);
    // ── Gantt Tasks ──
    case 'ganttRangeTaskHigh': return taskHigh;
    case 'ganttRangeTaskMedium': return taskMid;
    case 'ganttRangeTaskLow': return taskLow;
    case 'ganttRangeTaskDefault': return taskDefault;
    case 'ganttTaskText': return Colors.white;
    // ── Page ──
    case 'homePageBackground': return dark ? surfPageD : surfPageL;
    case 'homeCardBackground': return dark ? surfCardD : surfCardL;
    case 'homeCardBorder': return dark ? const Color(0x0FFFFFFF) : const Color(0x12000000);
    case 'homeTitleText': return dark ? textPriD : textPriL;
    case 'homeBodyText': return dark ? textSecD : textSecL;
    // ── Progress ──
    case 'homeProgressValue': return dark ? textPriD : textPriL;
    case 'homeProgressSymbol': return dark ? primaryD : primaryL;
    case 'homeProgressCaption': return dark ? primaryD : primaryL;
    // ── Buttons ──
    case 'commonFabBackground': return dark ? primaryD : primaryL;
    case 'commonFabIcon': return Colors.white;
    case 'commonButtonBackground': return dark ? primaryD : primaryL;
    case 'commonButtonText': return Colors.white;
    // ── Input ──
    case 'commonInputFill': return dark ? surfFillD : surfFillL;
    case 'commonInputLabel': return dark ? textSecD : textSecL;
    case 'commonInputText': return dark ? textPriD : textPriL;
    case 'commonInputBorder': return dark ? gridMajorD : gridMajorL;
    // ── AppBar & Misc ──
    case 'commonAppBarBackground': return dark ? surfPageD : surfPageL;
    case 'commonAppBarTitle': return dark ? textPriD : textPriL;
    case 'commonErrorText': return taskHigh;
    case 'commonDivider': return dark ? gridMajorD : gridMajorL;
    default: return Colors.grey;
  }
}

class ColorPreset {
  final String id;
  String name;
  final bool isBuiltin;

  final Map<String, Color> _lightColors;
  final Map<String, Color> _darkColors;

  ColorPreset({
    String? id,
    required this.name,
    this.isBuiltin = false,
    Map<String, Color>? lightColors,
    Map<String, Color>? darkColors,
  })  : id = id ?? _generateId(),
        _lightColors = {},
        _darkColors = {} {
    for (final k in _allKeys) {
      _lightColors[k] = _def(k, Brightness.light);
      _darkColors[k] = _def(k, Brightness.dark);
    }
    if (lightColors != null) _lightColors.addAll(lightColors);
    if (darkColors != null) _darkColors.addAll(darkColors);
  }

  static ColorPreset defaultPreset() => ColorPreset(
        id: '_builtin', name: '默认配置', isBuiltin: true);

  Color colorByKey(String key, Brightness brightness) {
    final map = brightness == Brightness.light ? _lightColors : _darkColors;
    return map[key] ?? Colors.grey;
  }

  void setColorByKey(String key, Color c, Brightness brightness) {
    if (brightness == Brightness.light) {
      _lightColors[key] = c;
    } else {
      _darkColors[key] = c;
    }
  }

  Map<String, dynamic> toJson() {
    final lightJson = <String, String>{};
    final darkJson = <String, String>{};
    for (final k in _allKeys) {
      lightJson[k] = _lightColors[k]!.toHex();
      darkJson[k] = _darkColors[k]!.toHex();
    }
    return {
      'id': id,
      'name': name,
      'isBuiltin': isBuiltin,
      'lightColors': lightJson,
      'darkColors': darkJson,
    };
  }

  factory ColorPreset.fromJson(Map<String, dynamic> json) {
    Color? pc(String hex) {
      if (hex.isEmpty) return null;
      try {
        return Color(int.parse(hex, radix: 16));
      } catch (_) {
        return null;
      }
    }

    final lightRaw = json['lightColors'] as Map<String, dynamic>?;
    final darkRaw = json['darkColors'] as Map<String, dynamic>?;
    final light = <String, Color>{};
    final dark = <String, Color>{};
    if (lightRaw != null) {
      for (final e in lightRaw.entries) {
        final c = pc(e.value as String? ?? '');
        if (c != null) light[e.key] = c;
      }
    }
    if (darkRaw != null) {
      for (final e in darkRaw.entries) {
        final c = pc(e.value as String? ?? '');
        if (c != null) dark[e.key] = c;
      }
    }
    return ColorPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      isBuiltin: json['isBuiltin'] as bool? ?? false,
      lightColors: light,
      darkColors: dark,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ColorPreset && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

extension ColorHex on Color {
  String toHex() => toARGB32().toRadixString(16).padLeft(8, '0');
}
