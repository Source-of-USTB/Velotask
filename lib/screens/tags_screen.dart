import 'package:flutter/material.dart';
import 'package:velotask/l10n/app_localizations.dart';
import 'package:velotask/models/tag.dart';
import 'package:velotask/services/todo_storage.dart';
import 'package:velotask/theme/app_theme.dart';
import 'package:velotask/utils/logger.dart';
import 'package:velotask/utils/tag_color.dart';
import 'package:velotask/widgets/color/channel_row.dart';

class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  final TodoStorage _storage = TodoStorage();
  List<Tag> _tags = [];
  static final Logger _logger = AppLogger.getLogger('TagsScreen');

  @override
  void initState() {
    super.initState();
    _logger.info('TagsScreen initialized');
    _loadTags();
  }

  Future<void> _loadTags() async {
    try {
      final tags = await _storage.loadTags();
      if (mounted) {
        setState(() {
          _tags = tags;
        });
      }
    } catch (e) {
      _logger.severe('Failed to load tags', e);
    }
  }

  Color _parseTagColor(Tag tag) => tag.displayColor;

  BoxDecoration _surfaceDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
      ),
    );
  }

  void _showAddTagDialog() {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    Color selectedColor = Colors.blue;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            l10n.addNewTag,
            style: AppTheme.dialogTitleStyle(context),
          ),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.tagName,
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  _buildColorPicker(
                    ctx,
                    color: selectedColor,
                    onChanged: (c) => setDialogState(() => selectedColor = c),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final colorHex =
                    '#${selectedColor.toARGB32().toRadixString(16).substring(2)}';
                final tag = Tag.unsaved(name: name, color: colorHex);
                final messenger = ScaffoldMessenger.of(ctx);
                try {
                  await _storage.addTag(tag);
                } catch (_) {
                  if (ctx.mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(l10n.failedToAddTag)),
                    );
                  }
                  return;
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _loadTags();
              },
              child: Text(l10n.create),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTagDialog(Tag tag) {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController(text: tag.name);
    Color editColor = _parseTagColor(tag);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            l10n.editTagColor,
            style: AppTheme.dialogTitleStyle(context),
          ),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.tagName,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildColorPicker(
                    ctx,
                    color: editColor,
                    onChanged: (c) => setDialogState(() => editColor = c),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final colorHex =
                    '#${editColor.toARGB32().toRadixString(16).substring(2)}';
                await _storage.updateTag(
                  tag.copyWith(name: name, color: colorHex),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                _loadTags();
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker(
    BuildContext ctx, {
    required Color color,
    required ValueChanged<Color> onChanged,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChannelRow(color: color, onChanged: onChanged, channel: 'R'),
        const SizedBox(height: 6),
        ChannelRow(color: color, onChanged: onChanged, channel: 'G'),
        const SizedBox(height: 6),
        ChannelRow(color: color, onChanged: onChanged, channel: 'B'),
        const SizedBox(height: 6),
        ChannelRow(color: color, onChanged: onChanged, channel: 'A'),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '#${color.toARGB32().toRadixString(16).substring(2)}',
              style: AppTheme.bodyMediumStyle(context),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.manageTags,
          style: AppTheme.pageTitleStyle(
            context,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
      body: _tags.isEmpty
          ? ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 28,
                  ),
                  decoration: _surfaceDecoration(context),
                  child: Column(
                    children: [
                      Icon(
                        Icons.label_outline,
                        size: 54,
                        color: Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.noTags,
                        style: AppTheme.bodyStrongStyle(context).copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: _tags.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final tag = _tags[index];
                final tagColor = _parseTagColor(tag);
                return Container(
                  decoration: _surfaceDecoration(context),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    leading: GestureDetector(
                      onTap: () => _showEditTagDialog(tag),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: tagColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.label, color: tagColor, size: 18),
                      ),
                    ),
                    title: Text(tag.name),
                    titleTextStyle: AppTheme.bodyMediumStrongStyle(
                      context,
                    ).copyWith(color: Theme.of(context).colorScheme.onSurface),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: tagColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await _storage.deleteTag(tag.id);
                            _loadTags();
                          },
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _showEditTagDialog(tag),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTagDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
