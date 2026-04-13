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

  final List<Color> _availableColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.brown,
    Colors.grey,
  ];

  @override
  void initState() {
    super.initState();
    _logger.info('TagsScreen initialized');
    _loadTags();
  }

  Future<void> _loadTags() async {
    try {
      final tags = await _storage.loadTags();
      setState(() {
        _tags = tags;
      });
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

    // Use toARGB32() instead of deprecated .value
    final colorHex =
        '#${_selectedColor.toARGB32().toRadixString(16).substring(2)}';
    final newTag = Tag.unsaved(name: name, color: colorHex);

    try {
      await _storage.addTag(newTag);
      _logger.info('Successfully added tag: ${newTag.name}');
    } catch (e) {
      // If insertion failed (e.g., unique constraint), show a friendly message
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
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            l10n.addNewTag,
            style: AppTheme.dialogTitleStyle(context),
          ),
          content: Column(
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableColors.map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: _selectedColor == color
                            ? Border.all(
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            FilledButton(onPressed: _addTag, child: Text(l10n.create)),
          ],
        ),
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
                Color tagColor = Colors.blue;
                if (tag.color != null) {
                  try {
                    tagColor = Color(
                      int.parse(tag.color!.replaceAll('#', '0xFF')),
                    );
                  } catch (_) {}
                }
                return Container(
                  decoration: _surfaceDecoration(context),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: tagColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.label, color: tagColor, size: 18),
                    ),
                    title: Text(tag.name),
                    titleTextStyle: AppTheme.bodyMediumStrongStyle(
                      context,
                    ).copyWith(color: Theme.of(context).colorScheme.onSurface),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteTag(tag),
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                    ),
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
