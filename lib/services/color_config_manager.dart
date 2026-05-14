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
  String _activePresetId = '_builtin';
  bool _initialized = false;

  List<ColorPreset> get presets => List.unmodifiable(_presets);
  String get activePresetId => _activePresetId;

  ColorPreset? get activePreset {
    try {
      return _presets.firstWhere((p) => p.id == _activePresetId);
    } catch (_) {
      return _presets.isNotEmpty ? _presets.first : null;
    }
  }

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
        _presets = [ColorPreset.defaultPreset()];
        await _save();
        return;
      }
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      _activePresetId = json['activePresetId'] as String? ?? '_builtin';

      final list = json['presets'] as List<dynamic>?;
      if (list == null) {
        // Old format: presets had per-brightness fields. Rebuild from scratch.
        _presets = [ColorPreset.defaultPreset()];
        await _save();
        return;
      }

      _presets = list
          .map((e) {
            final m = e as Map<String, dynamic>;
            // Old format check: if it has 'brightness' key, skip it
            if (m.containsKey('brightness')) return null;
            return ColorPreset.fromJson(m);
          })
          .whereType<ColorPreset>()
          .toList();

      if (!_presets.any((p) => p.id == '_builtin')) {
        _presets.insert(0, ColorPreset.defaultPreset());
      }
      if (_presets.isEmpty) {
        _presets = [ColorPreset.defaultPreset()];
      }
      if (!_presets.any((p) => p.id == _activePresetId)) {
        _activePresetId = '_builtin';
      }

      _log.info('Loaded ${_presets.length} presets');
    } catch (e) {
      _log.severe('Failed to load color config', e);
      _presets = [ColorPreset.defaultPreset()];
    }
  }

  Future<void> _save() async {
    final json = {
      'activePresetId': _activePresetId,
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
    if (updated.isBuiltin) return false;
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
    if (preset == null || preset.isBuiltin) return false;
    _presets.removeWhere((p) => p.id == id);
    if (_activePresetId == id) {
      _activePresetId = _presets.first.id;
    }
    await _save();
    notifyListeners();
    _log.info('Deleted preset: $id');
    return true;
  }

  bool canDeletePreset(String id) {
    final preset = presetById(id);
    if (preset == null || preset.isBuiltin) return false;
    return _presets.length > 1;
  }

  Future<void> setActivePreset(String id) async {
    if (!_presets.any((p) => p.id == id)) return;
    _activePresetId = id;
    await _save();
    notifyListeners();
    _log.info('Active preset changed: $id');
  }

  Future<void> resetBuiltins() async {
    _presets.removeWhere((p) => p.id == '_builtin');
    _presets.insert(0, ColorPreset.defaultPreset());
    _activePresetId = '_builtin';
    await _save();
    notifyListeners();
    _log.info('Reset builtin preset to defaults');
  }

  ColorScheme toColorScheme(Brightness brightness) {
    final p = activePreset ?? ColorPreset.defaultPreset();
    final b = brightness;
    if (b == Brightness.light) {
      return ColorScheme.light(
        primary: p.colorByKey('homeTitleText', b),
        onPrimary: p.colorByKey('commonFabIcon', b),
        secondary: p.colorByKey('homeProgressSymbol', b),
        onSecondary: p.colorByKey('commonButtonText', b),
        surface: p.colorByKey('homeCardBackground', b),
        error: p.colorByKey('commonErrorText', b),
      );
    } else {
      return ColorScheme.dark(
        primary: p.colorByKey('homeTitleText', b),
        onPrimary: p.colorByKey('commonFabIcon', b),
        secondary: p.colorByKey('homeProgressSymbol', b),
        onSecondary: p.colorByKey('commonButtonText', b),
        surface: p.colorByKey('homeCardBackground', b),
        error: p.colorByKey('commonErrorText', b),
      );
    }
  }
}
