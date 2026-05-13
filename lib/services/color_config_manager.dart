import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:velotask/models/color_preset.dart';
import 'package:velotask/utils/logger.dart';

class ColorConfigManager extends ChangeNotifier {
  static ColorConfigManager? _instance;
  static ColorConfigManager get instance {
    _instance ??= ColorConfigManager._();
    return _instance!;
  }

  ColorConfigManager._();

  static final Logger _log = AppLogger.getLogger('ColorConfigManager');

  static const _fileName = 'color_config.json';

  List<ColorPreset> _presets = [];
  String _activeLightPresetId = '_builtin_light';
  String _activeDarkPresetId = '_builtin_dark';
  bool _initialized = false;

  List<ColorPreset> get presets => List.unmodifiable(_presets);
  String get activeLightPresetId => _activeLightPresetId;
  String get activeDarkPresetId => _activeDarkPresetId;

  ColorPreset? get activeLightPreset {
    try {
      return _presets.firstWhere((p) => p.id == _activeLightPresetId);
    } catch (_) {
      return _presets.isNotEmpty ? _presets.first : null;
    }
  }

  ColorPreset? get activeDarkPreset {
    try {
      return _presets.firstWhere((p) => p.id == _activeDarkPresetId);
    } catch (_) {
      return _presets.isNotEmpty ? _presets.last : null;
    }
  }

  List<ColorPreset> lightPresets() =>
      _presets.where((p) => p.brightness == Brightness.light).toList();

  List<ColorPreset> darkPresets() =>
      _presets.where((p) => p.brightness == Brightness.dark).toList();

  ColorPreset? presetById(String id) {
    try {
      return _presets.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> init() async {
    if (_initialized) return;
    await _load();
    _initialized = true;
  }

  Future<File> get _configFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<void> _load() async {
    try {
      final file = await _configFile;
      if (!await file.exists()) {
        _log.info('No color config file, creating defaults');
        _presets = [ColorPreset.defaultLight(), ColorPreset.defaultDark()];
        await _save();
        return;
      }
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      _activeLightPresetId = json['activeLightPresetId'] as String? ?? '_builtin_light';
      _activeDarkPresetId = json['activeDarkPresetId'] as String? ?? '_builtin_dark';
      final list = json['presets'] as List<dynamic>? ?? [];
      _presets = list
          .map((e) => ColorPreset.fromJson(e as Map<String, dynamic>))
          .toList();
      _ensureBuiltins();
      _log.info('Loaded ${_presets.length} presets');
    } catch (e) {
      _log.severe('Failed to load color config', e);
      _presets = [ColorPreset.defaultLight(), ColorPreset.defaultDark()];
    }
  }

  void _ensureBuiltins() {
    if (!_presets.any((p) => p.id == '_builtin_light')) {
      _presets.insert(0, ColorPreset.defaultLight());
    }
    if (!_presets.any((p) => p.id == '_builtin_dark')) {
      _presets.add(ColorPreset.defaultDark());
    }
  }

  Future<void> _save() async {
    final json = {
      'activeLightPresetId': _activeLightPresetId,
      'activeDarkPresetId': _activeDarkPresetId,
      'presets': _presets.map((p) => p.toJson()).toList(),
    };
    final file = await _configFile;
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
  }

  Future<bool> addPreset(ColorPreset preset) async {
    if (_presets.any((p) => p.id == preset.id)) {
      _log.warning('Duplicate preset id: ${preset.id}');
      return false;
    }
    _presets.add(preset);
    await _save();
    notifyListeners();
    _log.info('Added preset: ${preset.name}');
    return true;
  }

  Future<bool> updatePreset(ColorPreset updated) async {
    final idx = _presets.indexWhere((p) => p.id == updated.id);
    if (idx == -1) return false;
    _presets[idx] = updated;
    await _save();
    notifyListeners();
    _log.info('Updated preset: ${updated.name}');
    return true;
  }

  Future<bool> deletePreset(String id) async {
    final preset = presetById(id);
    if (preset == null) return false;
    final sameBrightness =
        _presets.where((p) => p.brightness == preset.brightness).length;
    if (sameBrightness <= 1) return false;
    _presets.removeWhere((p) => p.id == id);
    if (_activeLightPresetId == id) {
      _activeLightPresetId =
          _presets.firstWhere((p) => p.brightness == Brightness.light).id;
    }
    if (_activeDarkPresetId == id) {
      _activeDarkPresetId =
          _presets.firstWhere((p) => p.brightness == Brightness.dark).id;
    }
    await _save();
    notifyListeners();
    _log.info('Deleted preset: $id');
    return true;
  }

  bool canDeletePreset(String id) {
    final preset = presetById(id);
    if (preset == null) return false;
    return _presets
            .where((p) => p.brightness == preset.brightness)
            .length >
        1;
  }

  Future<void> setActivePreset(String id) async {
    final preset = presetById(id);
    if (preset == null) return;
    if (preset.brightness == Brightness.light) {
      _activeLightPresetId = id;
    } else {
      _activeDarkPresetId = id;
    }
    await _save();
    notifyListeners();
    _log.info('Active preset changed: ${preset.name}');
  }

  Future<void> resetBuiltins() async {
    _presets.removeWhere((p) => p.id == '_builtin_light');
    _presets.removeWhere((p) => p.id == '_builtin_dark');
    _presets.insert(0, ColorPreset.defaultLight());
    _presets.add(ColorPreset.defaultDark());
    _activeLightPresetId = '_builtin_light';
    _activeDarkPresetId = '_builtin_dark';
    await _save();
    notifyListeners();
    _log.info('Reset builtin presets to defaults');
  }

  Color colorFor(Brightness brightness, Color Function(ColorPreset p) selector) {
    final preset =
        brightness == Brightness.light ? activeLightPreset : activeDarkPreset;
    if (preset == null) return Colors.grey;
    return selector(preset);
  }

  ColorScheme toColorScheme(Brightness brightness) {
    final preset =
        brightness == Brightness.light ? activeLightPreset : activeDarkPreset;
    if (preset == null) {
      return brightness == Brightness.light
          ? const ColorScheme.light()
          : const ColorScheme.dark();
    }
    if (brightness == Brightness.light) {
      return ColorScheme.light(
        primary: preset.primaryColor,
        onPrimary: Colors.white,
        secondary: preset.primaryColor,
        onSecondary: Colors.white,
        surface: preset.surfaceColor,
        error: preset.errorColor,
      );
    } else {
      return ColorScheme.dark(
        primary: preset.primaryColor,
        onPrimary: preset.surfaceColor,
        secondary: preset.accentColor,
        onSecondary: preset.surfaceColor,
        surface: preset.surfaceColor,
        error: preset.errorColor,
      );
    }
  }
}
