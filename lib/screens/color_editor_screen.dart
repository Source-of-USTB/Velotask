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
  final _ctrls = <String, TextEditingController>{};
  final _focuses = <String, FocusNode>{};
  final _errors = <String, String?>{};
  String? _nameError;
  String? _pendingNewId;

  late String _activeId;
  late ColorPreset _data;

  static const _fields = [
    'primaryColor', 'backgroundColor', 'surfaceColor',
    'highPriority', 'mediumPriority', 'lowPriority',
    'errorColor', 'accentColor',
  ];
  static const _chs = ['R', 'G', 'B', 'A'];

  // ── init / dispose ──

  @override
  void initState() {
    super.initState();
    _mgr.addListener(_onConfigChanged);
    _activeId = widget.presetId ?? _currentBrightnessActiveId();
    _data = _copy(_requirePreset(_activeId));
    _nameCtrl.text = _data.name;
    _makeControllers();
  }

  @override
  void dispose() {
    _mgr.removeListener(_onConfigChanged);
    _nameCtrl.dispose();
    for (final c in _ctrls.values) { c.dispose(); }
    for (final f in _focuses.values) { f.dispose(); }
    super.dispose();
  }

  // ── helpers ──

  String _currentBrightnessActiveId() {
    final b = PlatformDispatcher.instance.platformBrightness;
    return b == Brightness.light ? _mgr.activeLightPresetId : _mgr.activeDarkPresetId;
  }

  ColorPreset _requirePreset(String id) {
    return _mgr.presetById(id) ?? _mgr.activeLightPreset ?? ColorPreset.defaultLight();
  }

  ColorPreset _copy(ColorPreset p) => ColorPreset(
    id: p.id, name: p.name, brightness: p.brightness, isBuiltin: p.isBuiltin,
    primaryColor: p.primaryColor, backgroundColor: p.backgroundColor,
    surfaceColor: p.surfaceColor, highPriority: p.highPriority,
    mediumPriority: p.mediumPriority, lowPriority: p.lowPriority,
    errorColor: p.errorColor, accentColor: p.accentColor,
  );

  Color _get(String k) {
    switch (k) {
      case 'primaryColor': return _data.primaryColor;
      case 'backgroundColor': return _data.backgroundColor;
      case 'surfaceColor': return _data.surfaceColor;
      case 'highPriority': return _data.highPriority;
      case 'mediumPriority': return _data.mediumPriority;
      case 'lowPriority': return _data.lowPriority;
      case 'errorColor': return _data.errorColor;
      case 'accentColor': return _data.accentColor;
      default: return Colors.grey;
    }
  }

  void _set(String k, int r, int g, int b, int a) {
    final c = Color.fromARGB(a, r, g, b);
    setState(() {
      switch (k) {
        case 'primaryColor': _data.primaryColor = c; break;
        case 'backgroundColor': _data.backgroundColor = c; break;
        case 'surfaceColor': _data.surfaceColor = c; break;
        case 'highPriority': _data.highPriority = c; break;
        case 'mediumPriority': _data.mediumPriority = c; break;
        case 'lowPriority': _data.lowPriority = c; break;
        case 'errorColor': _data.errorColor = c; break;
        case 'accentColor': _data.accentColor = c; break;
      }
    });
  }

  int _chVal(Color c, String ch) {
    switch (ch) {
      case 'R': return (c.r * 255).round();
      case 'G': return (c.g * 255).round();
      case 'B': return (c.b * 255).round();
      case 'A': return (c.a * 255).round();
      default: return 0;
    }
  }

  String _fieldLabel(String k) {
    final l = AppLocalizations.of(context)!;
    switch (k) {
      case 'primaryColor': return l.primaryColor;
      case 'backgroundColor': return l.backgroundColor;
      case 'surfaceColor': return l.surfaceColor;
      case 'highPriority': return l.highPriorityColor;
      case 'mediumPriority': return l.mediumPriorityColor;
      case 'lowPriority': return l.lowPriorityColor;
      case 'errorColor': return l.errorColor;
      case 'accentColor': return l.accentColor;
      default: return k;
    }
  }

  List<ColorPreset> _sameBrightness() =>
      _mgr.presets.where((p) => p.brightness == _data.brightness).toList();

  bool get _canDelete => _mgr.canDeletePreset(_activeId);

  // ── controllers ──

  void _makeControllers() {
    for (final k in _fields) {
      final c = _get(k);
      for (final ch in _chs) {
        final id = '$k-$ch';
        _ctrls[id] = TextEditingController(text: _chVal(c, ch).toString());
        _focuses[id] = FocusNode()..addListener(() => _onBlur(id, k));
      }
    }
  }

  void _syncDisplays(String k) {
    final c = _get(k);
    for (final ch in _chs) {
      final id = '$k-$ch';
      if (!_focuses[id]!.hasFocus) {
        _ctrls[id]!.text = _chVal(c, ch).toString();
      }
      _errors[id] = null;
    }
  }

  void _syncAllDisplays() {
    for (final k in _fields) { _syncDisplays(k); }
  }

  // ── channel commit ──

  void _onBlur(String id, String k) {
    if (_focuses[id]!.hasFocus) return;
    _commit(id, k);
  }

  void _commit(String id, String k) {
    final raw = _ctrls[id]!.text;
    final v = int.tryParse(raw);
    final prev = _get(k);
    final ch = id.split('-').last;
    if (v == null || v < 0 || v > 255) {
      _ctrls[id]!.text = _chVal(prev, ch).toString();
      setState(() => _errors[id] = '0-255');
    } else {
      setState(() => _errors[id] = null);
      if (v != _chVal(prev, ch)) {
        final r = ch == 'R' ? v : (prev.r * 255).round();
        final g = ch == 'G' ? v : (prev.g * 255).round();
        final b = ch == 'B' ? v : (prev.b * 255).round();
        final a = ch == 'A' ? v : (prev.a * 255).round();
        _set(k, r, g, b, a);
        _syncDisplays(k);
      }
    }
  }

  void _commitAll() {
    for (final k in _fields) {
      for (final ch in _chs) { _commit('$k-$ch', k); }
    }
  }

  // ── actions ──

  void _switchTo(String id) {
    _activeId = id;
    _data = _copy(_requirePreset(id));
    _nameCtrl.text = _data.name;
    _nameError = null;
    _syncAllDisplays();
    setState(() {});
  }

  Future<void> _createNew() async {
    final l = AppLocalizations.of(context)!;
    final p = ColorPreset(
      name: '', brightness: _data.brightness,
      primaryColor: _data.primaryColor, backgroundColor: _data.backgroundColor,
      surfaceColor: _data.surfaceColor, highPriority: _data.highPriority,
      mediumPriority: _data.mediumPriority, lowPriority: _data.lowPriority,
      errorColor: _data.errorColor, accentColor: _data.accentColor,
    );
    _pendingNewId = p.id;
    if (await _mgr.addPreset(p)) return;
    _pendingNewId = null;
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.presetNameHint)));
  }

  Future<void> _apply() async {
    _commitAll();
    final l = AppLocalizations.of(context)!;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = l.presetNameHint);
      return;
    }
    for (final id in _errors.keys) {
      if (_errors[id] != null) return;
    }
    _data.name = name;
    await _mgr.updatePreset(_data);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l.apply}: $_data.name')));
      Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    if (!_canDelete) return;
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deletePreset),
        content: Text('${l.deletePreset} "${_data.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(MaterialLocalizations.of(context).cancelButtonLabel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete)),
        ],
      ),
    );
    if (ok != true) return;
    final delId = _activeId;
    final next = _sameBrightness().firstWhere((p) => p.id != delId);
    await _mgr.deletePreset(delId);
    if (mounted) _switchTo(next.id);
  }

  Future<void> _resetBuiltins() async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.resetBuiltins),
        content: Text(l.resetBuiltins),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(MaterialLocalizations.of(context).cancelButtonLabel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.resetBuiltins)),
        ],
      ),
    );
    if (ok == true) await _mgr.resetBuiltins();
  }

  void _onConfigChanged() {
    if (!mounted) return;
    if (_pendingNewId != null && _mgr.presetById(_pendingNewId!) != null) {
      _switchTo(_pendingNewId!);
      _pendingNewId = null;
    }
    setState(() {});
  }

  // ── build ──

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.colorSettings, style: AppTheme.pageTitleStyle(context, color: t.primaryColor)),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: _canDelete ? t.colorScheme.error : t.disabledColor),
            onPressed: _canDelete ? _delete : null,
            tooltip: l.deletePreset,
          ),
          const SizedBox(width: 4),
          FilledButton(onPressed: _apply, child: Text(l.apply)),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            children: [
              _buildSelector(t),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(labelText: l.presetName, hintText: l.presetNameHint, errorText: _nameError),
                controller: _nameCtrl,
                onChanged: (v) => setState(() { _data.name = v; _nameError = null; }),
              ),
              const SizedBox(height: 24),
              for (final k in _fields) _buildRow(k, t),
              const SizedBox(height: 24),
              TextButton.icon(onPressed: _resetBuiltins, icon: const Icon(Icons.restore), label: Text(l.resetBuiltins)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelector(ThemeData t) {
    final l = AppLocalizations.of(context)!;
    final presets = _sameBrightness();
    final globalActiveId = _data.brightness == Brightness.light
        ? _mgr.activeLightPresetId : _mgr.activeDarkPresetId;

    return PopupMenuButton<String>(
      initialValue: _activeId,
      offset: const Offset(0, 48),
      onSelected: (id) => id == '__new__' ? _createNew() : _switchTo(id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(border: Border.all(color: t.colorScheme.outlineVariant), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Container(width: 24, height: 24, decoration: BoxDecoration(color: _data.primaryColor, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(_data.name.isEmpty ? '…' : _data.name, style: AppTheme.bodyMediumStrongStyle(context))),
          if (_activeId == globalActiveId)
            Text(l.activePresetLabel, style: AppTheme.smallMediumStyle(context, color: t.colorScheme.primary)),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_drop_down),
        ]),
      ),
      itemBuilder: (ctx) => [
        for (final p in presets)
          PopupMenuItem<String>(
            value: p.id,
            child: Row(children: [
              Container(width: 20, height: 20, decoration: BoxDecoration(color: p.primaryColor, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(child: Text(p.name)),
              if (p.id == globalActiveId) Text(l.activePresetLabel, style: AppTheme.tinyBoldStyle(ctx, color: Theme.of(ctx).colorScheme.primary)),
              if (p.id == _activeId) const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.check, size: 16)),
            ]),
          ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(value: '__new__', child: Row(children: [const Icon(Icons.add, size: 18), const SizedBox(width: 10), Text(l.newPreset)])),
      ],
    );
  }

  Widget _buildRow(String k, ThemeData t) {
    final c = _get(k);
    final hasErr = _chs.any((ch) => _errors['$k-$ch'] != null);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_fieldLabel(k), style: AppTheme.bodyMediumStrongStyle(context)),
        const SizedBox(height: 8),
        Row(children: [
          _chInput(k, 'R'), const SizedBox(width: 8),
          _chInput(k, 'G'), const SizedBox(width: 8),
          _chInput(k, 'B'), const SizedBox(width: 8),
          _chInput(k, 'A'), const SizedBox(width: 12),
          Container(width: 36, height: 36, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(8), border: Border.all(color: t.colorScheme.outlineVariant))),
        ]),
        if (hasErr) Padding(padding: const EdgeInsets.only(top: 4), child: Text(AppLocalizations.of(context)!.invalidColorValue, style: TextStyle(color: t.colorScheme.error, fontSize: 12))),
      ]),
    );
  }

  Widget _chInput(String k, String ch) {
    final id = '$k-$ch';
    final hasErr = _errors[id] != null;
    return SizedBox(
      width: 56,
      child: TextField(
        controller: _ctrls[id],
        focusNode: _focuses[id],
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          labelText: ch, isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          border: hasErr ? const OutlineInputBorder(borderSide: BorderSide(color: Colors.red)) : null,
          enabledBorder: hasErr ? const OutlineInputBorder(borderSide: BorderSide(color: Colors.red)) : null,
        ),
      ),
    );
  }
}
