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
  final _colorErrors = <String, String?>{};

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

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.bodyMediumStrongStyle(context)),
          const SizedBox(height: 8),
          Row(
            children: [
              _channelInput(
                label: 'R',
                value: (color.r * 255).round(),
                onChanged: (v) => _setColor(key, v, (color.g * 255).round(), (color.b * 255).round(), (color.a * 255).round()),
              ),
              const SizedBox(width: 8),
              _channelInput(
                label: 'G',
                value: (color.g * 255).round(),
                onChanged: (v) => _setColor(key, (color.r * 255).round(), v, (color.b * 255).round(), (color.a * 255).round()),
              ),
              const SizedBox(width: 8),
              _channelInput(
                label: 'B',
                value: (color.b * 255).round(),
                onChanged: (v) => _setColor(key, (color.r * 255).round(), (color.g * 255).round(), v, (color.a * 255).round()),
              ),
              const SizedBox(width: 8),
              _channelInput(
                label: 'A',
                value: (color.a * 255).round(),
                onChanged: (v) => _setColor(key, (color.r * 255).round(), (color.g * 255).round(), (color.b * 255).round(), v),
              ),
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
          if (_colorErrors[key] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _colorErrors[key]!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _channelInput({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return SizedBox(
      width: 56,
      child: TextField(
        controller: TextEditingController(text: value.toString()),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        ),
        onChanged: (raw) {
          final parsed = int.tryParse(raw);
          if (parsed == null) return;
          final clamped = parsed.clamp(0, 255);
          onChanged(clamped);
        },
      ),
    );
  }
}
