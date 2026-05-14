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
  final _nameFocus = FocusNode();
  String? _nameError;
  String? _pendingNewId;

  late String _activeId;
  late ColorPreset _data;

  static const _groups = <_Group>[
    _Group('Gantt — Grid', [
      'ganttMonthGridLine','ganttWeekGridLine','ganttRowDivider','ganttWeekendStripe',
    ]),
    _Group('Gantt — Header', [
      'ganttHeaderBackground','ganttHeaderWeekendBg','ganttHeaderDivider',
      'ganttHeaderText','ganttHeaderWeekendText','ganttHeaderTodayText','ganttHeaderTodayBg',
    ]),
    _Group('Gantt — Tasks & Markers', [
      'ganttNowLine','ganttDeadlineTaskFill',
      'ganttRangeTaskHigh','ganttRangeTaskMedium','ganttRangeTaskLow','ganttRangeTaskDefault',
      'ganttTaskText',
    ]),
    _Group('Page', [
      'homePageBackground','homeCardBackground','homeCardBorder',
      'homeTitleText','homeBodyText',
    ]),
    _Group('Progress', [
      'homeProgressValue','homeProgressSymbol','homeProgressCaption',
    ]),
    _Group('Buttons & FAB', [
      'commonFabBackground','commonFabIcon','commonButtonBackground','commonButtonText',
    ]),
    _Group('Input', [
      'commonInputFill','commonInputLabel','commonInputText','commonInputBorder',
    ]),
    _Group('AppBar & Misc', [
      'commonAppBarBackground','commonAppBarTitle','commonErrorText','commonDivider',
    ]),
  ];

  @override
  void initState() {
    super.initState();
    _mgr.addListener(_onConfigChanged);
    _nameFocus.addListener(_onNameFocusChange);
    _activeId = widget.presetId ?? _mgr.activePresetId;
    _data = _copy(_requirePreset(_activeId));
    _nameCtrl.text = _data.name;
  }

  @override
  void dispose() {
    _mgr.removeListener(_onConfigChanged);
    _nameFocus.removeListener(_onNameFocusChange);
    _nameCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  ColorPreset _requirePreset(String id) {
    return _mgr.presetById(id) ?? _mgr.activePreset ?? ColorPreset.defaultPreset();
  }

  ColorPreset _copy(ColorPreset p) {
    final c = ColorPreset(id: p.id, name: p.name, isBuiltin: p.isBuiltin);
    for (final g in _groups) {
      for (final k in g.keys) {
        c.setColorByKey(k, p.colorByKey(k, Brightness.light), Brightness.light);
        c.setColorByKey(k, p.colorByKey(k, Brightness.dark), Brightness.dark);
      }
    }
    return c;
  }

  String _colorLabel(String k) {
    final l = AppLocalizations.of(context)!;
    switch (k) {
      case 'ganttMonthGridLine': return l.ganttMonthGridLine;
      case 'ganttWeekGridLine': return l.ganttWeekGridLine;
      case 'ganttRowDivider': return l.ganttRowDivider;
      case 'ganttWeekendStripe': return l.ganttWeekendStripe;
      case 'ganttNowLine': return l.ganttNowLine;
      case 'ganttHeaderBackground': return l.ganttHeaderBackground;
      case 'ganttHeaderWeekendBg': return l.ganttHeaderWeekendBg;
      case 'ganttHeaderDivider': return l.ganttHeaderDivider;
      case 'ganttHeaderText': return l.ganttHeaderText;
      case 'ganttHeaderWeekendText': return l.ganttHeaderWeekendText;
      case 'ganttHeaderTodayText': return l.ganttHeaderTodayText;
      case 'ganttHeaderTodayBg': return l.ganttHeaderTodayBg;
      case 'ganttDeadlineTaskFill': return l.ganttDeadlineTaskFill;
      case 'ganttRangeTaskHigh': return l.ganttRangeTaskHigh;
      case 'ganttRangeTaskMedium': return l.ganttRangeTaskMedium;
      case 'ganttRangeTaskLow': return l.ganttRangeTaskLow;
      case 'ganttRangeTaskDefault': return l.ganttRangeTaskDefault;
      case 'ganttTaskText': return l.ganttTaskText;
      case 'homePageBackground': return l.homePageBackground;
      case 'homeCardBackground': return l.homeCardBackground;
      case 'homeCardBorder': return l.homeCardBorder;
      case 'homeProgressValue': return l.homeProgressValue;
      case 'homeProgressSymbol': return l.homeProgressSymbol;
      case 'homeProgressCaption': return l.homeProgressCaption;
      case 'homeTitleText': return l.homeTitleText;
      case 'homeBodyText': return l.homeBodyText;
      case 'commonFabBackground': return l.commonFabBackground;
      case 'commonFabIcon': return l.commonFabIcon;
      case 'commonButtonBackground': return l.commonButtonBackground;
      case 'commonButtonText': return l.commonButtonText;
      case 'commonInputFill': return l.commonInputFill;
      case 'commonInputLabel': return l.commonInputLabel;
      case 'commonInputText': return l.commonInputText;
      case 'commonInputBorder': return l.commonInputBorder;
      case 'commonAppBarBackground': return l.commonAppBarBackground;
      case 'commonAppBarTitle': return l.commonAppBarTitle;
      case 'commonErrorText': return l.commonErrorText;
      case 'commonDivider': return l.commonDivider;
      default: return k;
    }
  }

  bool get _isBuiltin => _data.isBuiltin;
  bool get _canDelete => _mgr.canDeletePreset(_activeId);

  bool get _hasChanges {
    final original = _mgr.presetById(_activeId);
    if (original == null) return true;
    if (_nameCtrl.text.trim() != original.name) return true;
    for (final g in _groups) {
      for (final k in g.keys) {
        if (_data.colorByKey(k, Brightness.light) != original.colorByKey(k, Brightness.light)) return true;
        if (_data.colorByKey(k, Brightness.dark) != original.colorByKey(k, Brightness.dark)) return true;
      }
    }
    return false;
  }

  void _switchTo(String id) {
    _activeId = id;
    _data = _copy(_requirePreset(id));
    _nameCtrl.text = _data.name;
    _nameError = null;
    setState(() {});
  }

  void _onNameFocusChange() {
    if (_nameFocus.hasFocus) return;
    _saveName();
  }

  Future<void> _saveName() async {
    if (_isBuiltin) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || name == _data.name) return;
    _data.name = name;
    await _mgr.updatePreset(_data);
  }

  Future<void> _createNew() async {
    final l = AppLocalizations.of(context)!;
    final p = ColorPreset(name: _data.name);
    for (final g in _groups) {
      for (final k in g.keys) {
        p.setColorByKey(k, _data.colorByKey(k, Brightness.light), Brightness.light);
        p.setColorByKey(k, _data.colorByKey(k, Brightness.dark), Brightness.dark);
      }
    }
    _pendingNewId = p.id;
    if (await _mgr.addPreset(p)) return;
    _pendingNewId = null;
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.presetNameHint)));
  }

  Future<void> _apply() async {
    final l = AppLocalizations.of(context)!;
    if (!_isBuiltin) {
      final name = _nameCtrl.text.trim();
      if (name.isEmpty) {
        setState(() => _nameError = l.presetNameHint);
        return;
      }
      _data.name = name;
      await _mgr.updatePreset(_data);
    }
    await _mgr.setActivePreset(_activeId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l.apply}: $_data.name')));
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
    final next = _mgr.presets.firstWhere((p) => p.id != delId);
    await _mgr.deletePreset(delId);
    if (mounted) _switchTo(next.id);
  }

  void _onConfigChanged() {
    if (!mounted) return;
    if (_pendingNewId != null && _mgr.presetById(_pendingNewId!) != null) {
      _switchTo(_pendingNewId!);
      _pendingNewId = null;
    }
    setState(() {});
  }

  Future<void> _editColor(String key, Brightness brightness) async {
    if (_isBuiltin) return;
    Color c = _data.colorByKey(key, brightness);
    final isLight = brightness == Brightness.light;
    final l = AppLocalizations.of(context)!;
    final result = await showDialog<Color>(
      context: context,
      builder: (ctx) => _ColorEditDialog(
        title: '${_colorLabel(key)}  — ${isLight ? l.lightLabel : l.darkLabel}',
        initialColor: c,
      ),
    );
    if (result != null) {
      setState(() => _data.setColorByKey(key, result, brightness));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = Theme.of(context);
    final activeId = _mgr.activePresetId;
    final presets = _mgr.presets;

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
          FilledButton(
            onPressed: (_activeId == activeId && !_hasChanges) ? null : _apply,
            child: Text(l.apply),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            children: [
              _buildHeader(presets, activeId),
              const SizedBox(height: 24),
              _buildColorColumnHeaders(),
              const SizedBox(height: 8),
              for (final g in _groups) _buildGroup(g, t),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(List<ColorPreset> presets, String activeId) {
    final l = AppLocalizations.of(context)!;
    final t = Theme.of(context);

    return Container(
      padding: const EdgeInsets.only(left: 12, top: 10, bottom: 10, right: 2),
      decoration: BoxDecoration(
        border: Border.all(color: t.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        if (_isBuiltin)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(Icons.lock_outline, size: 20, color: t.colorScheme.outline),
          ),
        Expanded(
          child: TextField(
            controller: _nameCtrl,
            focusNode: _nameFocus,
            readOnly: _isBuiltin,
            decoration: InputDecoration(
              hintText: l.presetNameHint,
              errorText: _nameError,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            ),
            onChanged: _isBuiltin ? null : (v) => setState(() { _nameError = null; }),
            onSubmitted: _isBuiltin ? null : (_) => _saveName(),
          ),
        ),
        PopupMenuButton<String>(
          initialValue: _activeId,
          offset: const Offset(0, 48),
          onSelected: (id) {
            if (id == '__new__') {
              _createNew();
            } else {
              _switchTo(id);
            }
          },
          itemBuilder: (ctx) => [
            for (final p in presets)
              PopupMenuItem<String>(
                value: p.id,
                child: Row(children: [
                  if (p.isBuiltin) ...[
                    Icon(Icons.lock_outline, size: 14, color: Theme.of(ctx).colorScheme.outline),
                    const SizedBox(width: 6),
                  ],
                  Expanded(child: Text(p.name)),
                  if (p.id == activeId) Text(l.activePresetLabel, style: AppTheme.tinyBoldStyle(ctx, color: Theme.of(ctx).colorScheme.primary)),
                  if (p.id == _activeId) const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.check, size: 16)),
                ]),
              ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(value: '__new__', child: Row(children: [const Icon(Icons.add, size: 18), const SizedBox(width: 10), Text(l.newPreset)])),
          ],
          child: const SizedBox(width: 44, height: 44, child: Icon(Icons.arrow_drop_down, size: 28)),
        ),
      ]),
    );
  }

  static const double _blockSize = 40.0;
  static const double _blockGap = 10.0;

  Widget _buildColorColumnHeaders() {
    final l = AppLocalizations.of(context)!;
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Text(l.colorGroupLabel, style: AppTheme.captionStrongStyle(context, color: t.colorScheme.outline)),
        const Expanded(child: SizedBox()),
        _headerChip(l.lightLabel),
        const SizedBox(width: _blockGap),
        _headerChip(l.darkLabel),
      ]),
    );
  }

  Widget _headerChip(String label) {
    return Container(
      width: _blockSize,
      padding: const EdgeInsets.symmetric(vertical: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: AppTheme.captionStrongStyle(context, color: Theme.of(context).primaryColor)),
    );
  }

  Widget _buildGroup(_Group group, ThemeData t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Text(group.title, style: AppTheme.sectionTitleStyle(context, color: t.primaryColor)),
        ),
        ...group.keys.map((k) => _buildColorRow(k)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildColorRow(String key) {
    final lightColor = _data.colorByKey(key, Brightness.light);
    final darkColor = _data.colorByKey(key, Brightness.dark);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Expanded(
          child: Text(_colorLabel(key), style: AppTheme.bodyMediumStyle(context)),
        ),
        SizedBox(
          width: _blockSize, height: _blockSize,
          child: _colorBlock(lightColor, () => _editColor(key, Brightness.light)),
        ),
        const SizedBox(width: _blockGap),
        SizedBox(
          width: _blockSize, height: _blockSize,
          child: _colorBlock(darkColor, () => _editColor(key, Brightness.dark)),
        ),
      ]),
    );
  }

  Widget _colorBlock(Color color, VoidCallback? onTap) {
    final t = Theme.of(context);
    final editable = !_isBuiltin;
    return MouseRegion(
      cursor: editable ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: t.colorScheme.outlineVariant),
          ),
        ),
      ),
    );
  }
}

class _Group {
  final String title;
  final List<String> keys;
  const _Group(this.title, this.keys);
}

// ── Color Edit Dialog ──

class _ColorEditDialog extends StatefulWidget {
  final String title;
  final Color initialColor;
  const _ColorEditDialog({required this.title, required this.initialColor});

  @override
  State<_ColorEditDialog> createState() => _ColorEditDialogState();
}

class _ColorEditDialogState extends State<_ColorEditDialog> {
  late Color _color;

  @override
  void initState() {
    super.initState();
    _color = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title, style: AppTheme.dialogTitleStyle(context)),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _ChannelRow(color: _color, onChanged: (c) => setState(() => _color = c), channel: 'R'),
            const SizedBox(height: 6),
            _ChannelRow(color: _color, onChanged: (c) => setState(() => _color = c), channel: 'G'),
            const SizedBox(height: 6),
            _ChannelRow(color: _color, onChanged: (c) => setState(() => _color = c), channel: 'B'),
            const SizedBox(height: 6),
            _ChannelRow(color: _color, onChanged: (c) => setState(() => _color = c), channel: 'A'),
            const SizedBox(height: 12),
            Row(children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(
                color: _color, borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              )),
              const SizedBox(width: 12),
              Text('#${_color.toARGB32().toRadixString(16).substring(2)}',
                style: AppTheme.bodyMediumStyle(context)),
            ]),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          onPressed: () => Navigator.pop(context, _color),
          child: Text(l.save),
        ),
      ],
    );
  }
}

class _ChannelRow extends StatefulWidget {
  final Color color;
  final ValueChanged<Color> onChanged;
  final String channel;
  const _ChannelRow({required this.color, required this.onChanged, required this.channel});

  @override
  State<_ChannelRow> createState() => _ChannelRowState();
}

class _ChannelRowState extends State<_ChannelRow> {
  late TextEditingController _ctrl;
  late FocusNode _focus;
  int _lastValid = 0;

  @override
  void initState() {
    super.initState();
    _lastValid = _channelVal(widget.color, widget.channel);
    _ctrl = TextEditingController(text: _lastValid.toString());
    _focus = FocusNode();
    _focus.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_ChannelRow old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus) {
      final v = _channelVal(widget.color, widget.channel);
      if (v != _lastValid || widget.channel != old.channel) {
        _lastValid = v;
        _ctrl.text = v.toString();
      }
    }
  }

  int _channelVal(Color c, String ch) {
    switch (ch) {
      case 'R': return (c.r * 255).round();
      case 'G': return (c.g * 255).round();
      case 'B': return (c.b * 255).round();
      case 'A': return (c.a * 255).round();
      default: return 0;
    }
  }

  void _onFocusChange() {
    if (_focus.hasFocus) return;
    final raw = _ctrl.text;
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed < 0 || parsed > 255) {
      _ctrl.text = _lastValid.toString();
      return;
    }
    if (parsed == _lastValid) return;
    _lastValid = parsed;
    final ch = widget.channel;
    final c = widget.color;
    final r = ch == 'R' ? parsed : (c.r * 255).round();
    final g = ch == 'G' ? parsed : (c.g * 255).round();
    final b = ch == 'B' ? parsed : (c.b * 255).round();
    final a = ch == 'A' ? parsed : (c.a * 255).round();
    widget.onChanged(Color.fromARGB(a, r, g, b));
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final chLabel = widget.channel == 'R' ? l.redLabel
        : widget.channel == 'G' ? l.greenLabel
        : widget.channel == 'B' ? l.blueLabel
        : l.alphaLabel;

    return Row(children: [
      SizedBox(width: 20, child: Text(chLabel)),
      const SizedBox(width: 8),
      SizedBox(
        width: 64,
        child: TextField(
          controller: _ctrl,
          focusNode: _focus,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          ),
        ),
      ),
      const SizedBox(width: 8),
      SliderTheme(
        data: SliderThemeData(
          trackHeight: 4,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        ),
        child: Expanded(
          child: Slider(
            value: _lastValid.toDouble(),
            min: 0, max: 255,
            onChanged: (v) {
              final iv = v.round();
              _ctrl.text = iv.toString();
              setState(() => _lastValid = iv);
            },
            onChangeEnd: (v) {
              final iv = v.round();
              final ch = widget.channel;
              final c = widget.color;
              final r = ch == 'R' ? iv : (c.r * 255).round();
              final g = ch == 'G' ? iv : (c.g * 255).round();
              final b = ch == 'B' ? iv : (c.b * 255).round();
              final a = ch == 'A' ? iv : (c.a * 255).round();
              widget.onChanged(Color.fromARGB(a, r, g, b));
            },
          ),
        ),
      ),
    ]);
  }
}
