import 'package:flutter/material.dart';
import 'package:velotask/models/tag.dart';
import 'package:velotask/services/todo_storage.dart';

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
    _loadTags();
  }

  Future<void> _loadTags() async {
    final tags = await _storage.loadTags();
    setState(() {
      _tags = tags;
    });
  }

  Future<void> _addTag() async {
    final name = _tagNameController.text.trim();
    if (name.isEmpty) return;

    // Use toARGB32() instead of deprecated .value
    final colorHex =
        '#${_selectedColor.toARGB32().toRadixString(16).substring(2)}';
    final newTag = Tag(name: name, color: colorHex);

    try {
      await _storage.addTag(newTag);
    } catch (e) {
      // If insertion failed (e.g., unique constraint), show a friendly message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tag "${newTag.name}" already exists')),
      );
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
    await _storage.deleteTag(tag.id);
    _loadTags();
  }

  void _showAddTagDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Tag'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _tagNameController,
                decoration: const InputDecoration(
                  labelText: 'Tag Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Select Color'),
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
                            ? Border.all(color: Colors.black, width: 2)
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
              child: const Text('Cancel'),
            ),
            FilledButton(onPressed: _addTag, child: const Text('Add')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Tags')),
      body: _tags.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.label_outline,
                    size: 64,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tags created yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _tags.length,
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
                return ListTile(
                  leading: Icon(Icons.label, color: tagColor),
                  title: Text(tag.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteTag(tag),
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
