import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velotask/l10n/app_localizations.dart';
import 'package:velotask/models/color_preset.dart';
import 'package:velotask/services/color_config_manager.dart';
import 'package:velotask/theme/app_theme.dart';

class ColorEditorScreen extends StatefulWidget {
  final ColorPreset preset;

  const ColorEditorScreen({super.key, required this.preset});

  @override
  State<ColorEditorScreen> createState() => _ColorEditorScreenState();
}

class _ColorEditorScreenState extends State<ColorEditorScreen> {
  final _mgr = ColorConfigManager.instance;
  late ColorPreset _editing;
  String? _nameError;

  final _controllers = <String, TextEditingController>{};
  final _focusNodes = <String, FocusNode>{};
  final _channelErrors = <String, String?>{};

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
    _editing = ColorPreset(
      id: widget.preset.id,
      name: widget.preset.name,
      brightness: widget.preset.brightness,
      isBuiltin: widget.preset.isBuiltin,
      primaryColor: widget.preset.primaryColor,
      backgroundColor: widget.preset.backgroundColor,
      surfaceColor: widget.preset.surfaceColor,
      highPriority: widget.preset.highPriority,
      mediumPriority: widget.preset.mediumPriority,
      lowPriority: widget.preset.lowPriority,
      errorColor: widget.preset.errorColor,
      accentColor: widget.preset.accentColor,
    );
    _initControllers();
  }

  void _initControllers() {
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
        _syncControllersFor(colorKey);
      }
    }
  }

  void _syncControllersFor(String key) {
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

  bool _validateAll() {
    final l10n = AppLocalizations.of(context)!;
    bool valid = true;

    if (_editing.name.trim().isEmpty) {
      setState(() => _nameError = l10n.presetNameHint);
      valid = false;
    } else {
      _nameError = null;
    }

    // Commit all focused fields before checking
    for (final key in _colorFields) {
      for (final ch in _channels) {
        final id = '$key-$ch';
        _commitChannel(id, key);
      }
    }

    for (final id in _channelErrors.keys) {
      if (_channelErrors[id] != null) valid = false;
    }

    return valid;
  }

  Future<void> _apply() async {
    if (!_validateAll()) return;
    await _mgr.updatePreset(_editing);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.apply}: ${_editing.name}')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    for (final id in _controllers.keys) {
      _controllers[id]?.dispose();
    }
    for (final id in _focusNodes.keys) {
      _focusNodes[id]?.dispose();
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
          l10n.editPreset,
          style: AppTheme.pageTitleStyle(context, color: theme.primaryColor),
        ),
        actions: [
          FilledButton(
            onPressed: _apply,
            child: Text(l10n.apply),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: l10n.presetName,
              hintText: l10n.presetNameHint,
              errorText: _nameError,
            ),
            controller: TextEditingController(text: _editing.name),
            onChanged: (v) {
              setState(() {
                _editing.name = v;
                _nameError = null;
              });
            },
          ),
          const SizedBox(height: 24),
          ..._colorFields.map((key) => _buildColorRow(context, key)),
        ],
      ),
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
              _channelInput(key: key, ch: 'R', color: color),
              const SizedBox(width: 8),
              _channelInput(key: key, ch: 'G', color: color),
              const SizedBox(width: 8),
              _channelInput(key: key, ch: 'B', color: color),
              const SizedBox(width: 8),
              _channelInput(key: key, ch: 'A', color: color),
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

  Widget _channelInput({
    required String key,
    required String ch,
    required Color color,
  }) {
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
