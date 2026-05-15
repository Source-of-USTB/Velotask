import 'package:flutter/material.dart';
import 'package:velotask/models/tag.dart';

extension TagColorExtension on Tag {
  Color get displayColor {
    if (color == null) return Colors.blue;
    try {
      return Color(int.parse(color!.replaceAll('#', '0xFF')));
    } catch (_) {
      return Colors.blue;
    }
  }
}
