import 'package:flutter/material.dart';
import 'package:velotask/l10n/app_localizations.dart';
import 'package:velotask/models/tag.dart';
import 'package:velotask/services/todo_storage.dart';
import 'package:velotask/theme/app_theme.dart';
import 'package:velotask/utils/logger.dart';

class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  final TodoStorage _storage = TodoStorage();
  List<Tag> _tags = [];
  final TextEditingController _tagNameController = TextEditingController();
  Color _selectedColor = Colors.blue;
  static final Logger _logger = AppLogger.getLogger('TagsScreen');

  List<Color> get _availableColors {
    final colors = <Color>[];
    for (int h = 0; h < 360; h += 24) {
      for (int v = 0; v < 3; v++) {
        final s = v == 0 ? 0.5 : v == 1 ? 0.75 : 1.0;
        colors.add(HSVColor.fromAHSV(1, h.toDouble(), s, 1.0).toColor());
      }
    }
    // Add grays
    for (int i = 0; i < 6; i++) {
      final v = (0xFF - i * 0x28).clamp(0, 255);
      colors.add(Color.fromARGB(255, v, v, v));
    }
    return colors;
  }

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

  Future<void> _addTag() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _tagNameController.text.trim();
    if (name.isEmpty) {
      _logger.warning('Attempted to add tag with empty name');
      return;
    }

    final colorHex =
        '#${_selectedColor.toARGB32().toRadixString(16).substring(2)}';
    final newTag = Tag.unsaved(name: name, color: colorHex);

    try {
      await _storage.addTag(newTag);
      _logger.info('Successfully added tag: ${newTag.name}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.failedToAddTag)));
      }
      _logger.warning('Tag already exists or failed to add: ${newTag.name}');
      return;
    }
    _tagNameController.clear();
    setState(() {
      _selectedColor = Colors.blue;
    });
    _loadTags();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteTag(Tag tag) async {
    try {
      await _storage.deleteTag(tag.id);
      _loadTags();
      _logger.info('Deleted tag: ${tag.name}');
    } catch (e) {
      _logger.severe('Failed to delete tag: ${tag.name}', e);
    }
  }

  Color _parseTagColor(Tag tag) {
    if (tag.color == null) return Colors.blue;
    try {
      return Color(
        int.parse(tag.color!.replaceAll('#', '0xFF')),
      );
    } catch (_) {
      return Colors.blue;
    }
  }

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
    _selectedColor = Colors.blue;
    _tagNameController.clear();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            l10n.addNewTag,
            style: AppTheme.dialogTitleStyle(context),
          ),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _tagNameController,
                  decoration: InputDecoration(
                    labelText: l10n.tagName,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.selectColor,
                  style: AppTheme.captionStrongStyle(context),
                ),
                const SizedBox(height: 8),
                _buildColorGrid((c) => setDialogState(() => _selectedColor = c)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(onPressed: _addTag, child: Text(l10n.create)),
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
            width: 320,
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
                Text(
                  l10n.selectColor,
                  style: AppTheme.captionStrongStyle(context),
                ),
                const SizedBox(height: 8),
                _buildColorGrid((c) => setDialogState(() => editColor = c),
                    selected: editColor),
              ],
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

  Widget _buildColorGrid(void Function(Color) onSelect,
      {Color? selected}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: GridView.builder(
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1,
        ),
        itemCount: _availableColors.length,
        itemBuilder: (context, index) {
          final color = _availableColors[index];
          final isSelected = selected != null &&
              selected.toARGB32() == color.toARGB32();
          return GestureDetector(
            onTap: () {
              onSelect(color);
              if (selected == null) {
                setState(() => _selectedColor = color);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 2.5,
                      )
                    : Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 0.5,
                      ),
              ),
            ),
          );
        },
      ),
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
                    ).copyWith(
                        color: Theme.of(context).colorScheme.onSurface),
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
                          onPressed: () => _deleteTag(tag),
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
