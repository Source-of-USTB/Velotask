import 'package:flutter/material.dart';
import 'package:velotask/l10n/app_localizations.dart';
import 'package:velotask/models/color_preset.dart';
import 'package:velotask/screens/color_editor_screen.dart';
import 'package:velotask/services/color_config_manager.dart';
import 'package:velotask/theme/app_theme.dart';

class ColorSettingsScreen extends StatefulWidget {
  const ColorSettingsScreen({super.key});

  @override
  State<ColorSettingsScreen> createState() => _ColorSettingsScreenState();
}

class _ColorSettingsScreenState extends State<ColorSettingsScreen> {
  final _mgr = ColorConfigManager.instance;

  @override
  void initState() {
    super.initState();
    _mgr.addListener(_onConfigChanged);
  }

  @override
  void dispose() {
    _mgr.removeListener(_onConfigChanged);
    super.dispose();
  }

  void _onConfigChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.colorSettings,
          style: AppTheme.pageTitleStyle(
            context,
            color: Theme.of(context).primaryColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _confirmResetBuiltins(context),
            child: Text(l10n.resetBuiltins),
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildPresetSection(
            context,
            title: l10n.lightPresets,
            presets: _mgr.lightPresets(),
            activeId: _mgr.activeLightPresetId,
          ),
          const Divider(),
          _buildPresetSection(
            context,
            title: l10n.darkPresets,
            presets: _mgr.darkPresets(),
            activeId: _mgr.activeDarkPresetId,
          ),
        ],
      ),
    );
  }

  Widget _buildPresetSection(
    BuildContext context, {
    required String title,
    required List<ColorPreset> presets,
    required String activeId,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: AppTheme.sectionTitleStyle(
              context,
              color: theme.primaryColor,
            ),
          ),
        ),
        ...presets.map((preset) => _buildPresetTile(context, preset, activeId)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: OutlinedButton.icon(
            onPressed: () => _createPreset(context, presetBrightness: presets.isNotEmpty ? presets.first.brightness : Brightness.light),
            icon: const Icon(Icons.add),
            label: Text(l10n.newPreset),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetTile(
    BuildContext context,
    ColorPreset preset,
    String activeId,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isActive = preset.id == activeId;

    return ListTile(
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: preset.primaryColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      title: Row(
        children: [
          Flexible(child: Text(preset.name)),
          if (preset.isBuiltin) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                l10n.builtinPreset,
                style: AppTheme.tinyBoldStyle(
                  context,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: isActive
          ? Text(
              l10n.activePresetLabel,
              style: AppTheme.smallMediumStyle(
                context,
                color: theme.colorScheme.primary,
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isActive)
            TextButton(
              onPressed: () => _mgr.setActivePreset(preset.id),
              child: Text(l10n.apply),
            ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => _editPreset(context, preset),
          ),
          if (!preset.isBuiltin)
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 20, color: theme.colorScheme.error),
              onPressed: () => _confirmDelete(context, preset),
            ),
        ],
      ),
      onTap: () => _editPreset(context, preset),
    );
  }

  Future<void> _editPreset(BuildContext context, ColorPreset preset) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ColorEditorScreen(preset: preset),
      ),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _createPreset(BuildContext context, {required Brightness presetBrightness}) async {
    final l10n = AppLocalizations.of(context)!;
    final nav = Navigator.of(context);
    final nameController = TextEditingController();
    ColorPreset? basePreset;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final presetsOfBrightness =
              _mgr.presets.where((p) => p.brightness == presetBrightness).toList();

          return AlertDialog(
            title: Text(l10n.createPreset),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.presetName,
                    hintText: l10n.presetNameHint,
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ColorPreset>(
                  initialValue: basePreset ?? presetsOfBrightness.firstOrNull,
                  decoration: InputDecoration(labelText: l10n.selectBasePreset),
                  items: presetsOfBrightness.map((p) {
                    return DropdownMenuItem(value: p, child: Text(p.name));
                  }).toList(),
                  onChanged: (v) => setDialogState(() => basePreset = v),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
              ),
              FilledButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  Navigator.pop(ctx, true);
                },
                child: Text(l10n.create),
              ),
            ],
          );
        },
      ),
    );

    if (result == true) {
      final name = nameController.text.trim();
      if (name.isEmpty) return;
      final source = basePreset ?? _mgr.presets.firstWhere(
        (p) => p.brightness == presetBrightness,
        orElse: () => presetBrightness == Brightness.light
            ? ColorPreset.defaultLight()
            : ColorPreset.defaultDark(),
      );
      final newPreset = ColorPreset(
        name: name,
        brightness: presetBrightness,
        primaryColor: source.primaryColor,
        backgroundColor: source.backgroundColor,
        surfaceColor: source.surfaceColor,
        highPriority: source.highPriority,
        mediumPriority: source.mediumPriority,
        lowPriority: source.lowPriority,
        errorColor: source.errorColor,
        accentColor: source.accentColor,
      );
      await _mgr.addPreset(newPreset);
      if (!mounted) return;
      final result2 = await nav.push<bool>(
        MaterialPageRoute(
          builder: (_) => ColorEditorScreen(preset: newPreset),
        ),
      );
      if (result2 == true && mounted) {
        setState(() {});
      }
    }
  }

  void _confirmDelete(BuildContext context, ColorPreset preset) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deletePreset),
        content: Text('${l10n.deletePreset} "${preset.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () {
              _mgr.deletePreset(preset.id);
              Navigator.pop(ctx);
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _confirmResetBuiltins(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.resetBuiltins),
        content: Text(l10n.resetBuiltins),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () {
              _mgr.resetBuiltins();
              Navigator.pop(ctx);
            },
            child: Text(l10n.resetBuiltins),
          ),
        ],
      ),
    );
  }
}
