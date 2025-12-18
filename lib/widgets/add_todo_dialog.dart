import 'package:flutter/material.dart';
import 'package:velotask/models/tag.dart';
import 'package:velotask/models/todo.dart';
import 'package:velotask/services/todo_storage.dart';
import 'package:velotask/widgets/dialog_components.dart';
import 'package:velotask/l10n/app_localizations.dart';

class AddTodoDialog extends StatefulWidget {
  final Todo? todo;
  final Function(
    String title,
    String desc,
    DateTime? startDate,
    DateTime? ddl,
    int importance,
    List<Tag> tags,
  )
  onAdd;

  const AddTodoDialog({super.key, required this.onAdd, this.todo});

  @override
  State<AddTodoDialog> createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends State<AddTodoDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime? _ddl;
  int _importance = 1;
  List<Tag> _availableTags = [];
  List<Tag> _selectedTags = [];
  final TodoStorage _storage = TodoStorage();

  @override
  void initState() {
    super.initState();
    _loadTags();
    if (widget.todo != null) {
      _titleController.text = widget.todo!.title;
      _descController.text = widget.todo!.description;
      _startDate =
          widget.todo!.startDate ?? widget.todo!.createdAt ?? DateTime.now();
      _ddl = widget.todo!.ddl;
      _importance = widget.todo!.importance;
      _selectedTags = widget.todo!.tags.toList();
    }
  }

  Future<void> _loadTags() async {
    final tags = await _storage.loadTags();
    setState(() {
      _availableTags = tags;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        widget.todo == null ? l10n.newTask : l10n.editTask,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Input
              DialogInputRow(
                icon: Icons.edit_outlined,
                isInput: true,
                child: TextField(
                  controller: _titleController,
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.titleHint,
                    hintStyle: TextStyle(
                      color: Colors.grey.withValues(alpha: 0.5),
                      fontWeight: FontWeight.normal,
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description Input
              DialogInputRow(
                icon: Icons.description_outlined,
                isInput: true,
                child: TextField(
                  controller: _descController,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: l10n.descHint,
                    hintStyle: TextStyle(
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    isDense: true,
                  ),
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
              const SizedBox(height: 24),

              // Date Picker
              DialogInputRow(
                icon: Icons.calendar_today_outlined,
                child: Row(
                  children: [
                    Expanded(
                      child: DialogDatePicker(
                        label: l10n.dateFrom,
                        date: _startDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 1),
                        ), // Allow today
                        onSelect: (d) {
                          if (d != null) {
                            setState(() {
                              _startDate = d;
                              // If DDL is before new start date, reset it or adjust it
                              if (_ddl != null && _ddl!.isBefore(d)) {
                                _ddl = null;
                              }
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DialogDatePicker(
                        label: l10n.dateTo,
                        date: _ddl,
                        firstDate: _startDate,
                        onSelect: (d) => setState(() => _ddl = d),
                        isOptional: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Priority Row
              DialogInputRow(
                icon: Icons.flag_outlined,
                child: PrioritySelector(
                  selectedPriority: _importance,
                  onPriorityChanged: (val) => setState(() => _importance = val),
                ),
              ),

              // Tags Row
              if (_availableTags.isNotEmpty) ...[
                const SizedBox(height: 16),
                DialogInputRow(
                  icon: Icons.label_outline,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _availableTags.map((tag) {
                      final isSelected = _selectedTags.any(
                        (t) => t.id == tag.id,
                      );
                      Color tagColor = Colors.blue;
                      if (tag.color != null) {
                        try {
                          tagColor = Color(
                            int.parse(tag.color!.replaceAll('#', '0xFF')),
                          );
                        } catch (_) {}
                      }
                      return FilterChip(
                        label: Text(tag.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.removeWhere((t) => t.id == tag.id);
                            }
                          });
                        },
                        backgroundColor: Colors.transparent,
                        selectedColor: tagColor.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? tagColor
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isSelected
                                ? tagColor
                                : Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty) {
              widget.onAdd(
                _titleController.text,
                _descController.text,
                _startDate,
                _ddl,
                _importance,
                _selectedTags,
              );
              Navigator.pop(context);
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            widget.todo == null ? l10n.create : l10n.save,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
