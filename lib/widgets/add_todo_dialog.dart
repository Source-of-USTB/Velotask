import 'package:flutter/material.dart';
import 'package:velotask/l10n/app_localizations.dart';
import 'package:velotask/models/tag.dart';
import 'package:velotask/models/todo.dart';
import 'package:velotask/services/todo_storage.dart';
import 'package:velotask/theme/app_theme.dart';
import 'package:velotask/widgets/dialog_components.dart';

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
    if (widget.todo != null) {
      _titleController.text = widget.todo!.title;
      _descController.text = widget.todo!.description;
      _startDate =
          widget.todo!.startDate ?? widget.todo!.createdAt ?? DateTime.now();
      _ddl = widget.todo!.ddl;
      _importance = widget.todo!.importance;
      // _selectedTags is initialized after _loadTags completes.
    }
    _loadTags();
  }

  Future<void> _loadTags() async {
    final tags = await _storage.loadTags();
    if (!mounted) {
      return;
    }
    setState(() {
      _availableTags = tags;
      if (widget.todo != null) {
        final todoTagIds = widget.todo!.tags.map((t) => t.id).toSet();
        _selectedTags = tags.where((t) => todoTagIds.contains(t.id)).toList();
      }
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogWidth = screenWidth > 700 ? 560.0 : screenWidth - 40;
    final maxDialogBodyHeight = screenHeight * 0.72;
    final useVerticalDateLayout = screenWidth < 420;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        widget.todo == null ? l10n.newTask : l10n.editTask,
        style: AppTheme.dialogTitleStyle(context),
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: maxDialogBodyHeight,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Input
              DialogInputRow(
                isInput: true,
                child: TextField(
                  controller: _titleController,
                  autofocus: true,
                  style: AppTheme.bodyStrongStyle(context),
                  decoration: InputDecoration(
                    hintText: l10n.titleHint,
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
                ),
              ),
              const SizedBox(height: 16),

              // Description Input
              DialogInputRow(
                isInput: true,
                child: TextField(
                  controller: _descController,
                  style: AppTheme.bodyStrongStyle(context),
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
                child: useVerticalDateLayout
                    ? Column(
                        children: [
                          DialogDatePicker(
                            label: l10n.dateFrom,
                            date: _startDate,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 1),
                            ),
                            onSelect: (d) {
                              if (d != null) {
                                setState(() {
                                  _startDate = d;
                                  if (_ddl != null && _ddl!.isBefore(d)) {
                                    _ddl = null;
                                  }
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          DialogDatePicker(
                            label: l10n.dateTo,
                            date: _ddl,
                            firstDate: _startDate,
                            onSelect: (d) => setState(() => _ddl = d),
                            isOptional: true,
                            includeTime: true,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: DialogDatePicker(
                              label: l10n.dateFrom,
                              date: _startDate,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 1),
                              ),
                              onSelect: (d) {
                                if (d != null) {
                                  setState(() {
                                    _startDate = d;
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
                              includeTime: true,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),

              // Priority Row
              DialogInputRow(
                child: PrioritySelector(
                  selectedPriority: _importance,
                  onPriorityChanged: (val) => setState(() => _importance = val),
                ),
              ),

              // Tags Row
              if (_availableTags.isNotEmpty) ...[
                const SizedBox(height: 16),
                DialogInputRow(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
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
                        materialTapTargetSize: MaterialTapTargetSize.padded,
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
            style: AppTheme.bodyStrongStyle(
              context,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
