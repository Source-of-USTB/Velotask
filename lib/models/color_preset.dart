import 'dart:math';

import 'package:flutter/material.dart';

String _generateId() {
  final r = Random();
  final ms = DateTime.now().microsecondsSinceEpoch;
  return '${ms.toRadixString(36)}_${r.nextInt(99999).toString().padLeft(5, '0')}';
}

const _allKeys = [
  'ganttMonthGridLine',
  'ganttWeekGridLine',
  'ganttRowDivider',
  'ganttWeekendStripe',
  'ganttNowLine',
  'ganttHeaderBackground',
  'ganttHeaderWeekendBg',
  'ganttHeaderDivider',
  'ganttHeaderText',
  'ganttHeaderWeekendText',
  'ganttHeaderTodayText',
  'ganttHeaderTodayBg',
  'ganttDeadlineTaskFill',
  'ganttRangeTaskHigh',
  'ganttRangeTaskMedium',
  'ganttRangeTaskLow',
  'ganttRangeTaskDefault',
  'ganttTaskText',
  'homePageBackground',
  'homeCardBackground',
  'homeCardBorder',
  'homeProgressValue',
  'homeProgressSymbol',
  'homeProgressCaption',
  'homeTitleText',
  'homeBodyText',
  'commonFabBackground',
  'commonFabIcon',
  'commonButtonBackground',
  'commonButtonText',
  'commonInputFill',
  'commonInputLabel',
  'commonInputText',
  'commonInputBorder',
  'commonAppBarBackground',
  'commonAppBarTitle',
  'commonErrorText',
  'commonDivider',
];

Color _def(String key, Brightness b) {
  final dark = b == Brightness.dark;
  const primaryL = Color(0xFF3B73E6);
  const primaryD = Color(0xFF6EA2FF);
  // Surface hierarchy
  const surfPageL = Color(0xFFF6F8FC);
  const surfCardL = Color(0xFFFFFFFF);
  const surfFillL = Color(0xFFEEF2F7);
  const surfHeaderL = Color(0xFFEDF1F7);
  const surfPageD = Color(0xFF0F1218);
  const surfCardD = Color(0xFF171B24);
  const surfFillD = Color(0xFF202635);
  const surfHeaderD = Color(0xFF151A24);
  // Grid / divider
  const gridMajorL = Color(0xFFCBD4E2);
  const gridMajorD = Color(0xFF3A4252);
  const gridMinorAlphaL = 0x60;
  const gridMinorAlphaD = 0x40;
  const gridRowAlphaL = 0x44;
  const gridRowAlphaD = 0x33;
  // Weekend
  const weekendL = Color(0xFFF1F4F9);
  const weekendD = Color(0xFF111722);
  // Text
  const textPriL = Color(0xFF1B1F29);
  const textSecL = Color(0xFF687284);
  const textPriD = Color(0xFFE4EAF3);
  const textSecD = Color(0xFF98A2B3);
  // Semantic task fills
  const taskHighL = Color(0xFFC94A44);
  const taskHighD = Color(0xFFD85A54);
  const taskMidL = Color(0xFFC9781C);
  const taskMidD = Color(0xFFD98A2B);
  const taskLowL = Color(0xFF2F8A58);
  const taskLowD = Color(0xFF3FA46B);
  const taskDefaultL = Color(0xFF557386);
  const taskDefaultD = Color(0xFF6F8B9E);
  // Now / deadline
  const nowRedL = Color(0xFFD85650);
  const nowRedD = Color(0xFFEF6B64);

  switch (key) {
    // ── Gantt Grid ──
    case 'ganttMonthGridLine':
      return dark ? gridMajorD : gridMajorL;
    case 'ganttWeekGridLine':
      return dark
          ? gridMajorD.withAlpha(gridMinorAlphaD)
          : gridMajorL.withAlpha(gridMinorAlphaL);
    case 'ganttRowDivider':
      return dark
          ? gridMajorD.withAlpha(gridRowAlphaD)
          : gridMajorL.withAlpha(gridRowAlphaL);
    case 'ganttWeekendStripe':
      return dark ? weekendD : weekendL;
    // ── Gantt Markers ──
    case 'ganttNowLine':
      return dark ? nowRedD : nowRedL;
    case 'ganttDeadlineTaskFill':
      return dark ? nowRedD : nowRedL;
    // ── Gantt Header ──
    case 'ganttHeaderBackground':
      return dark ? surfHeaderD : surfHeaderL;
    case 'ganttHeaderWeekendBg':
      return dark ? weekendD : weekendL;
    case 'ganttHeaderDivider':
      return dark ? gridMajorD : gridMajorL;
    case 'ganttHeaderText':
      return dark ? textPriD : textPriL;
    case 'ganttHeaderWeekendText':
      return dark ? textSecD : textSecL;
    case 'ganttHeaderTodayText':
      return dark ? primaryD : primaryL;
    case 'ganttHeaderTodayBg':
      return dark ? primaryD.withAlpha(0x1A) : primaryL.withAlpha(0x1A);
    // ── Gantt Tasks ──
    case 'ganttRangeTaskHigh':
      return dark ? taskHighD : taskHighL;
    case 'ganttRangeTaskMedium':
      return dark ? taskMidD : taskMidL;
    case 'ganttRangeTaskLow':
      return dark ? taskLowD : taskLowL;
    case 'ganttRangeTaskDefault':
      return dark ? taskDefaultD : taskDefaultL;
    case 'ganttTaskText':
      return Colors.white;
    // ── Page ──
    case 'homePageBackground':
      return dark ? surfPageD : surfPageL;
    case 'homeCardBackground':
      return dark ? surfCardD : surfCardL;
    case 'homeCardBorder':
      return dark ? const Color(0x10FFFFFF) : const Color(0x10000000);
    case 'homeTitleText':
      return dark ? textPriD : textPriL;
    case 'homeBodyText':
      return dark ? textSecD : textSecL;
    // ── Progress ──
    case 'homeProgressValue':
      return dark ? textPriD : textPriL;
    case 'homeProgressSymbol':
      return dark ? primaryD : primaryL;
    case 'homeProgressCaption':
      return dark ? primaryD : primaryL;
    // ── Buttons ──
    case 'commonFabBackground':
      return dark ? primaryD : primaryL;
    case 'commonFabIcon':
      return dark ? surfPageD : Colors.white;
    case 'commonButtonBackground':
      return dark ? primaryD : primaryL;
    case 'commonButtonText':
      return dark ? surfPageD : Colors.white;
    // ── Input ──
    case 'commonInputFill':
      return dark ? surfFillD : surfFillL;
    case 'commonInputLabel':
      return dark ? textSecD : textSecL;
    case 'commonInputText':
      return dark ? textPriD : textPriL;
    case 'commonInputBorder':
      return dark ? gridMajorD : gridMajorL;
    // ── AppBar & Misc ──
    case 'commonAppBarBackground':
      return dark ? surfPageD : surfPageL;
    case 'commonAppBarTitle':
      return dark ? textPriD : textPriL;
    case 'commonErrorText':
      return dark ? taskHighD : taskHighL;
    case 'commonDivider':
      return dark ? gridMajorD : gridMajorL;
    default:
      return Colors.grey;
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
  }) : id = id ?? _generateId(),
       _lightColors = {},
       _darkColors = {} {
    for (final k in _allKeys) {
      _lightColors[k] = _def(k, Brightness.light);
      _darkColors[k] = _def(k, Brightness.dark);
    }
    if (lightColors != null) _lightColors.addAll(lightColors);
    if (darkColors != null) _darkColors.addAll(darkColors);
  }

  static ColorPreset defaultPreset() =>
      ColorPreset(id: '_builtin', name: '默认配置', isBuiltin: true);

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
  bool operator ==(Object other) => other is ColorPreset && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

extension ColorHex on Color {
  String toHex() => toARGB32().toRadixString(16).padLeft(8, '0');
}
