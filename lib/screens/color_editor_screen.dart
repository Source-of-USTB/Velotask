import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velotask/l10n/app_localizations.dart';
import 'package:velotask/models/color_preset.dart';
import 'package:velotask/services/color_config_manager.dart';
import 'package:velotask/theme/app_theme.dart';

class ColorEditorScreen extends StatefulWidget {
  final String? presetId;

  const ColorEditorScreen({super.key, this.presetId});

  @override
  State<ColorEditorScreen> createState() => _ColorEditorScreenState();
}

class _ColorEditorScreenState extends State<ColorEditorScreen> {
  final _mgr = ColorConfigManager.instance;
  final _nameCtrl = TextEditingController();
  final _controllers = <String, TextEditingController>{};
  final _focusNodes = <String, FocusNode>{};
  final _channelErrors = <String, String?>{};
  String? _nameError;

  late String _editingPresetId;
  late ColorPreset _editing;
  String? _pendingNewId;

  static const _channels = ['R', 'G', 'B', 'A'];

  static const _colorFields = <String>[
    'primaryColor',
    'backgroundColor',
    'surfaceColor',
    'highPriority',
    'mediumPriority',
    'lowPriority',
    'errorColor',
    'accentColor',
  ];

  @override
  void initState() {
    super.initState();
    _mgr.addListener(_onConfigChanged);
    _initChannelControllers();

    final initialId = widget.presetId ?? _activeIdForCurrentBrightness();
    _loadPreset(initialId);
  }

  String _activeIdForCurrentBrightness() {
    final brightness = PlatformDispatcher.instance.platformBrightness;
    return brightness == Brightness.light
        ? _mgr.activeLightPresetId
        : _mgr.activeDarkPresetId;
  }

  void _onConfigChanged() {
    if (!mounted) return;
    if (_pendingNewId != null) {
      final exists = _mgr.presetById(_pendingNewId!);
      if (exists != null) {
        _loadPreset(_pendingNewId!);
        _pendingNewId = null;
      }
    }
    setState(() {});
  }

  void _loadPreset(String id) {
    final p = _mgr.presetById(id);
    if (p == null) {
      final fallback = _mgr.activeLightPreset ?? ColorPreset.defaultLight();
      _editingPresetId = fallback.id;
      _editing = _copyPreset(fallback);
    } else {
      _editingPresetId = id;
      _editing = _copyPreset(p);
    }
    _nameCtrl.text = _editing.name;
    _nameError = null;
    _syncAllControllers();
  }

  ColorPreset _copyPreset(ColorPreset p) => ColorPreset(
        id: p.id,
        name: p.name,
        brightness: p.brightness,
        isBuiltin: p.isBuiltin,
        primaryColor: p.primaryColor,
        backgroundColor: p.backgroundColor,
        surfaceColor: p.surfaceColor,
        highPriority: p.highPriority,
        mediumPriority: p.mediumPriority,
        lowPriority: p.lowPriority,
        errorColor: p.errorColor,
        accentColor: p.accentColor,
      );

  void _initChannelControllers() {
    for (final key in _colorFields) {
      final c = _getColor(key);
      for (final ch in _channels) {
        final id = '$key-$ch';
        _controllers[id] = TextEditingController(text: _channelText(c, ch));
        _focusNodes[id] = FocusNode();
        _focusNodes[id]!.addListener(() => _onFocusChange(id, key));
      }
    }
  }

  void _syncAllControllers() {
    for (final key in _colorFields) {
      final c = _getColor(key);
      for (final ch in _channels) {
        final id = '$key-$ch';
        if (!_focusNodes[id]!.hasFocus) {
          _controllers[id]!.text = _channelText(c, ch);
        }
        _channelErrors[id] = null;
      }
    }
  }

  String _channelText(Color c, String ch) {
    switch (ch) {
      case 'R': return (c.r * 255).round().toString();
      case 'G': return (c.g * 255).round().toString();
      case 'B': return (c.b * 255).round().toString();
      case 'A': return (c.a * 255).round().toString();
      default: return '0';
    }
  }

  int _channelValue(Color c, String ch) {
    switch (ch) {
      case 'R': return (c.r * 255).round();
      case 'G': return (c.g * 255).round();
      case 'B': return (c.b * 255).round();
      case 'A': return (c.a * 255).round();
      default: return 0;
    }
  }

  void _onFocusChange(String id, String colorKey) {
    if (_focusNodes[id]!.hasFocus) return;
    _commitChannel(id, colorKey);
  }

  void _commitChannel(String id, String colorKey) {
    final raw = _controllers[id]!.text;
    final parsed = int.tryParse(raw);
    final prevColor = _getColor(colorKey);
    final ch = id.split('-').last;

    if (parsed == null || parsed < 0 || parsed > 255) {
      _controllers[id]!.text = _channelText(prevColor, ch);
      setState(() => _channelErrors[id] = '0-255');
    } else {
      setState(() => _channelErrors[id] = null);
      final current = _channelValue(prevColor, ch);
      if (parsed != current) {
        final r = ch == 'R' ? parsed : (prevColor.r * 255).round();
        final g = ch == 'G' ? parsed : (prevColor.g * 255).round();
        final b = ch == 'B' ? parsed : (prevColor.b * 255).round();
        final a = ch == 'A' ? parsed : (prevColor.a * 255).round();
        _setColor(colorKey, r, g, b, a);
        _syncChannelDisplays(colorKey);
      }
    }
  }

  void _syncChannelDisplays(String key) {
    final c = _getColor(key);
    for (final ch in _channels) {
      final id = '$key-$ch';
      if (!_focusNodes[id]!.hasFocus) {
        _controllers[id]!.text = _channelText(c, ch);
      }
    }
  }

  Color _getColor(String key) {
    switch (key) {
      case 'primaryColor': return _editing.primaryColor;
      case 'backgroundColor': return _editing.backgroundColor;
      case 'surfaceColor': return _editing.surfaceColor;
      case 'highPriority': return _editing.highPriority;
      case 'mediumPriority': return _editing.mediumPriority;
      case 'lowPriority': return _editing.lowPriority;
      case 'errorColor': return _editing.errorColor;
      case 'accentColor': return _editing.accentColor;
      default: return Colors.grey;
    }
  }

  void _setColor(String key, int r, int g, int b, int a) {
    final c = Color.fromARGB(a, r, g, b);
    setState(() {
      switch (key) {
        case 'primaryColor': _editing.primaryColor = c; break;
        case 'backgroundColor': _editing.backgroundColor = c; break;
        case 'surfaceColor': _editing.surfaceColor = c; break;
        case 'highPriority': _editing.highPriority = c; break;
        case 'mediumPriority': _editing.mediumPriority = c; break;
        case 'lowPriority': _editing.lowPriority = c; break;
        case 'errorColor': _editing.errorColor = c; break;
        case 'accentColor': _editing.accentColor = c; break;
      }
    });
  }

  String _fieldLabel(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'primaryColor': return l10n.primaryColor;
      case 'backgroundColor': return l10n.backgroundColor;
      case 'surfaceColor': return l10n.surfaceColor;
      case 'highPriority': return l10n.highPriorityColor;
      case 'mediumPriority': return l10n.mediumPriorityColor;
      case 'lowPriority': return l10n.lowPriorityColor;
      case 'errorColor': return l10n.errorColor;
      case 'accentColor': return l10n.accentColor;
      default: return key;
    }
  }

  List<ColorPreset> _presetsForCurrentBrightness() {
    final b = _editing.brightness;
    return _mgr.presets.where((p) => p.brightness == b).toList();
  }

  bool get _canDelete =>
      _mgr.canDeletePreset(_editingPresetId);

  bool _validateAll() {
    final l10n = AppLocalizations.of(context)!;
    bool valid = true;

    if (_editing.name.trim().isEmpty) {
      setState(() => _nameError = l10n.presetNameHint);
      valid = false;
    } else {
      _nameError = null;
    }

    for (final key in _colorFields) {
      for (final ch in _channels) {
        _commitChannel('$key-$ch', key);
      }
    }

    for (final id in _channelErrors.keys) {
      if (_channelErrors[id] != null) valid = false;
    }

    return valid;
  }

  Future<void> _apply() async {
    if (!_validateAll()) return;
    _editing.name = _nameCtrl.text.trim();
    await _mgr.updatePreset(_editing);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${AppLocalizations.of(context)!.apply}: ${_editing.name}')),
    );
    Navigator.pop(context);
  }

  Future<void> _deletePreset() async {
    if (!_canDelete) return;
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deletePreset),
        content: Text('${l10n.deletePreset} "${_editing.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final deletedId = _editingPresetId;
    final siblings = _presetsForCurrentBrightness()
        .where((p) => p.id != deletedId)
        .toList();
    final nextId = siblings.first.id;
    await _mgr.deletePreset(deletedId);
    if (!mounted) return;
    _loadPreset(nextId);
  }

  void _switchPreset(String id) {
    _loadPreset(id);
  }

  Future<void> _createNewPreset() async {
    final l10n = AppLocalizations.of(context)!;
    final newPreset = ColorPreset(
      name: '',
      brightness: _editing.brightness,
      primaryColor: _editing.primaryColor,
      backgroundColor: _editing.backgroundColor,
      surfaceColor: _editing.surfaceColor,
      highPriority: _editing.highPriority,
      mediumPriority: _editing.mediumPriority,
      lowPriority: _editing.lowPriority,
      errorColor: _editing.errorColor,
      accentColor: _editing.accentColor,
    );
    _pendingNewId = newPreset.id;
    final ok = await _mgr.addPreset(newPreset);
    if (!ok && mounted) {
      _pendingNewId = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.presetNameHint)),
      );
    }
  }

  Future<void> _confirmReset() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.resetBuiltins),
        content: Text(l10n.resetBuiltins),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.resetBuiltins),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _mgr.resetBuiltins();
    }
  }

  @override
  void dispose() {
    _mgr.removeListener(_onConfigChanged);
    _nameCtrl.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.colorSettings,
          style: AppTheme.pageTitleStyle(context, color: theme.primaryColor),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline,
                color: _canDelete
                    ? theme.colorScheme.error
                    : theme.disabledColor),
            onPressed: _canDelete ? _deletePreset : null,
            tooltip: l10n.deletePreset,
          ),
          const SizedBox(width: 4),
          FilledButton(
            onPressed: _apply,
            child: Text(l10n.apply),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            children: [
          _buildPresetSelector(context),
          const SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(
              labelText: l10n.presetName,
              hintText: l10n.presetNameHint,
              errorText: _nameError,
            ),
            controller: _nameCtrl,
            onChanged: (v) {
              setState(() {
                _editing.name = v;
                _nameError = null;
              });
            },
          ),
          const SizedBox(height: 24),
          ..._colorFields.map((key) => _buildColorRow(context, key)),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _confirmReset,
            icon: const Icon(Icons.restore),
            label: Text(l10n.resetBuiltins),
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildPresetSelector(BuildContext context) {
    final theme = Theme.of(context);
    final presets = _presetsForCurrentBrightness();
    final activeId = _editing.brightness == Brightness.light
        ? _mgr.activeLightPresetId
        : _mgr.activeDarkPresetId;

    return PopupMenuButton<String>(
      initialValue: _editingPresetId,
      onSelected: (id) {
        if (id == '__new__') {
          _createNewPreset();
        } else {
          _switchPreset(id);
        }
      },
      offset: const Offset(0, 48),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _editing.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _editing.name.isEmpty ? '…' : _editing.name,
                style: AppTheme.bodyMediumStrongStyle(context),
              ),
            ),
            if (_editingPresetId == activeId)
              Text(
                AppLocalizations.of(context)!.activePresetLabel,
                style: AppTheme.smallMediumStyle(
                  context,
                  color: theme.colorScheme.primary,
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
      itemBuilder: (ctx) => [
        ...presets.map((p) {
          final isActive = p.id == _editingPresetId;
          final isActiveGlobal = p.id == activeId;
          return PopupMenuItem<String>(
            value: p.id,
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: p.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(p.name)),
                if (isActiveGlobal)
                  Text(
                    AppLocalizations.of(context)!.activePresetLabel,
                    style: AppTheme.tinyBoldStyle(
                      ctx,
                      color: Theme.of(ctx).colorScheme.primary,
                    ),
                  ),
                if (isActive)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.check, size: 16),
                  ),
              ],
            ),
          );
        }),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: '__new__',
          child: Row(
            children: [
              const Icon(Icons.add, size: 18),
              const SizedBox(width: 10),
              Text(AppLocalizations.of(context)!.newPreset),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorRow(BuildContext context, String key) {
    final color = _getColor(key);
    final label = _fieldLabel(context, key);
    final theme = Theme.of(context);
    final rowHasError = _channels.any((ch) => _channelErrors['$key-$ch'] != null);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.bodyMediumStrongStyle(context)),
          const SizedBox(height: 8),
          Row(
            children: [
              _channelInput(key: key, ch: 'R'),
              const SizedBox(width: 8),
              _channelInput(key: key, ch: 'G'),
              const SizedBox(width: 8),
              _channelInput(key: key, ch: 'B'),
              const SizedBox(width: 8),
              _channelInput(key: key, ch: 'A'),
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
              ),
            ],
          ),
          if (rowHasError)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                AppLocalizations.of(context)!.invalidColorValue,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _channelInput({required String key, required String ch}) {
    final id = '$key-$ch';
    final hasError = _channelErrors[id] != null;

    return SizedBox(
      width: 56,
      child: TextField(
        controller: _controllers[id],
        focusNode: _focusNodes[id],
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          labelText: ch,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          border: hasError
              ? const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                )
              : null,
          enabledBorder: hasError
              ? const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                )
              : null,
        ),
      ),
    );
  }
}
