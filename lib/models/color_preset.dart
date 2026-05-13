import 'dart:math';

import 'package:flutter/material.dart';

String _generateId() {
  final r = Random();
  final ms = DateTime.now().microsecondsSinceEpoch;
  return '${ms.toRadixString(36)}_${r.nextInt(99999).toString().padLeft(5, '0')}';
}

class ColorPreset {
  final String id;
  String name;
  final Brightness brightness;
  final bool isBuiltin;

  Color primaryColor;
  Color backgroundColor;
  Color surfaceColor;
  Color highPriority;
  Color mediumPriority;
  Color lowPriority;
  Color errorColor;
  Color accentColor;

  ColorPreset({
    String? id,
    required this.name,
    required this.brightness,
    this.isBuiltin = false,
    Color? primaryColor,
    Color? backgroundColor,
    Color? surfaceColor,
    Color? highPriority,
    Color? mediumPriority,
    Color? lowPriority,
    Color? errorColor,
    Color? accentColor,
  })  : id = id ?? _generateId(),
        primaryColor = primaryColor ?? _defaultPrimary(brightness),
        backgroundColor = backgroundColor ?? _defaultBackground(brightness),
        surfaceColor = surfaceColor ?? _defaultSurface(brightness),
        highPriority = highPriority ?? const Color(0xFFFF3F34),
        mediumPriority = mediumPriority ?? const Color(0xFFFFA801),
        lowPriority = lowPriority ?? const Color(0xFF0BE881),
        errorColor = errorColor ?? const Color(0xFFFF5E57),
        accentColor = accentColor ?? _defaultAccent(brightness);

  static Color _defaultPrimary(Brightness b) =>
      b == Brightness.light ? const Color(0xFF2C3E50) : const Color(0xFFECF0F1);

  static Color _defaultBackground(Brightness b) =>
      b == Brightness.light ? const Color(0xFFF5F6FA) : const Color(0xFF121212);

  static Color _defaultSurface(Brightness b) =>
      b == Brightness.light ? Colors.white : const Color(0xFF1E1E1E);

  static Color _defaultAccent(Brightness b) =>
      b == Brightness.light ? const Color(0xFF2C3E50) : const Color(0xFF3498DB);

  static ColorPreset defaultLight() => ColorPreset(
        id: '_builtin_light',
        name: '浅色默认',
        brightness: Brightness.light,
        isBuiltin: true,
      );

  static ColorPreset defaultDark() => ColorPreset(
        id: '_builtin_dark',
        name: '深色默认',
        brightness: Brightness.dark,
        isBuiltin: true,
      );

  ColorPreset copyWith({String? name}) {
    return ColorPreset(
      id: id,
      name: name ?? this.name,
      brightness: brightness,
      isBuiltin: isBuiltin,
      primaryColor: primaryColor,
      backgroundColor: backgroundColor,
      surfaceColor: surfaceColor,
      highPriority: highPriority,
      mediumPriority: mediumPriority,
      lowPriority: lowPriority,
      errorColor: errorColor,
      accentColor: accentColor,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brightness': brightness == Brightness.light ? 'light' : 'dark',
        'isBuiltin': isBuiltin,
        'primaryColor': primaryColor.toHex(),
        'backgroundColor': backgroundColor.toHex(),
        'surfaceColor': surfaceColor.toHex(),
        'highPriority': highPriority.toHex(),
        'mediumPriority': mediumPriority.toHex(),
        'lowPriority': lowPriority.toHex(),
        'errorColor': errorColor.toHex(),
        'accentColor': accentColor.toHex(),
      };

  factory ColorPreset.fromJson(Map<String, dynamic> json) => ColorPreset(
        id: json['id'] as String,
        name: json['name'] as String,
        brightness:
            json['brightness'] == 'light' ? Brightness.light : Brightness.dark,
        isBuiltin: json['isBuiltin'] as bool? ?? false,
        primaryColor: _parseColor(json['primaryColor']),
        backgroundColor: _parseColor(json['backgroundColor']),
        surfaceColor: _parseColor(json['surfaceColor']),
        highPriority: _parseColor(json['highPriority']),
        mediumPriority: _parseColor(json['mediumPriority']),
        lowPriority: _parseColor(json['lowPriority']),
        errorColor: _parseColor(json['errorColor']),
        accentColor: _parseColor(json['accentColor']),
      );

  static Color _parseColor(dynamic v) {
    if (v == null) return Colors.grey;
    if (v is int) return Color(v);
    if (v is String) return Color(int.parse(v, radix: 16));
    return Colors.grey;
  }

  @override
  bool operator ==(Object other) =>
      other is ColorPreset &&
      other.id == id &&
      other.primaryColor == primaryColor &&
      other.backgroundColor == backgroundColor &&
      other.surfaceColor == surfaceColor &&
      other.highPriority == highPriority &&
      other.mediumPriority == mediumPriority &&
      other.lowPriority == lowPriority &&
      other.errorColor == errorColor &&
      other.accentColor == accentColor;

  @override
  int get hashCode => Object.hash(id, primaryColor, backgroundColor, surfaceColor,
      highPriority, mediumPriority, lowPriority, errorColor, accentColor);
}

extension ColorHex on Color {
  String toHex() => toARGB32().toRadixString(16).padLeft(8, '0');
}
