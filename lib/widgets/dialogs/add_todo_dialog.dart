import 'package:flutter/material.dart';
import 'package:velotask/l10n/app_localizations.dart';
import 'package:velotask/models/tag.dart';
import 'package:velotask/models/todo.dart';
import 'package:velotask/services/todo_storage.dart';
import 'package:velotask/theme/app_theme.dart';
import 'package:velotask/utils/tag_color.dart';
import 'package:velotask/widgets/dialogs/dialog_components.dart';

typedef GroupedTodoSubmitCallback =
    void Function(
      String title,
      String desc,
      DateTime? startDate,
      DateTime? ddl,
      int importance,
      List<Tag> tags,
      TaskType taskType,
      int? parentTodoId,
      TaskGroupMode groupMode,
    );

class AddTodoDialog extends StatefulWidget {
  final Todo? todo;
  final List<Todo> allTodos;
  final Function(
    String title,
    String desc,
    DateTime? startDate,
    DateTime? ddl,
    int importance,
    List<Tag> tags,
    TaskType taskType,
  )
  onAdd;
  final GroupedTodoSubmitCallback? onAddWithGrouping;
  final VoidCallback? onDelete;

  const AddTodoDialog({
    super.key,
    required this.onAdd,
    this.todo,
    this.allTodos = const [],
    this.onAddWithGrouping,
    this.onDelete,
  });

  @override
  State<AddTodoDialog> createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends State<AddTodoDialog> {
  static final RegExp _tagPattern = RegExp(r'#([^\\]+)\\#');

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  DateTime? _startDate;
  DateTime? _ddl;
  int _importance = 1;
  TaskType _taskType = TaskType.deadline;
  int? _parentTodoId;
  TaskGroupMode _groupMode = TaskGroupMode.none;
  List<Tag> _availableTags = [];
  List<Tag> _selectedTags = [];
  bool _isSubmitting = false;
  bool _parentRequiredError = false;
  final TodoStorage _storage = TodoStorage();

  @override
  void initState() {
    super.initState();
    if (widget.todo != null) {
      _titleController.text = widget.todo!.title;
      _descController.text = widget.todo!.description;
      _startDate = widget.todo!.startDate ?? widget.todo!.createdAt;
      _ddl = widget.todo!.ddl;
      _importance = widget.todo!.importance;
      _taskType = widget.todo!.taskType;
      _parentTodoId = widget.todo!.parentTodoId;
      _groupMode = widget.todo!.groupMode;
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

  /// Returns (list of tag names found, cleaned description text).
  (List<String>, String) _extractInlineTags(String text) {
    final tagNames = <String>[];
    final cleaned = text.replaceAllMapped(_tagPattern, (match) {
      final name = match.group(1)!.trim();
      if (name.isNotEmpty) {
        tagNames.add(name);
      }
      return '';
    });
    return (tagNames, cleaned.trim());
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final submitGroupMode = _taskType == TaskType.daily
        ? TaskGroupMode.none
        : _groupMode;
    final selectedParentId = _validParentId();
    if (submitGroupMode.requiresParent && selectedParentId == null) {
      setState(() {
        _parentRequiredError = true;
        _isSubmitting = false;
      });
      return;
    }

    final (titleTagNames, cleanTitle) = _extractInlineTags(
      _titleController.text,
    );
    final (descTagNames, cleanDesc) = _extractInlineTags(_descController.text);

    final inlineTags = <Tag>[];
    final seenNormalized = <String>{};
    for (final name in [...titleTagNames, ...descTagNames]) {
      final normalized = name.trim().toLowerCase();
      if (seenNormalized.contains(normalized)) continue;
      seenNormalized.add(normalized);

      final existing = _availableTags.cast<Tag?>().firstWhere(
        (t) => t!.name.trim().toLowerCase() == normalized,
        orElse: () => null,
      );
      if (existing != null) {
        inlineTags.add(existing);
      } else {
        final newTag = await _storage.addTag(Tag.unsaved(name: name.trim()));
        inlineTags.add(newTag);
        _availableTags.add(newTag);
      }
    }

    final allTags = [..._selectedTags];
    for (final tag in inlineTags) {
      if (!allTags.any((t) => t.id == tag.id)) {
        allTags.add(tag);
      }
    }

    if (!mounted) return;

    final submitStartDate = _taskType == TaskType.task ? _startDate : null;
    final submitDdl = _taskType == TaskType.daily ? null : _ddl;
    final submitParentTodoId = submitGroupMode.requiresParent
        ? selectedParentId
        : null;

    final groupedCallback = widget.onAddWithGrouping;
    if (groupedCallback != null) {
      groupedCallback(
        cleanTitle,
        cleanDesc,
        submitStartDate,
        submitDdl,
        _importance,
        allTags,
        _taskType,
        submitParentTodoId,
        submitGroupMode,
      );
    } else {
      widget.onAdd(
        cleanTitle,
        cleanDesc,
        submitStartDate,
        submitDdl,
        _importance,
        allTags,
        _taskType,
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogWidth = screenWidth > (320 + 32) ? 320.0 : screenWidth - 32;
    final maxDialogBodyHeight = screenHeight * 0.72;
    final useVerticalDateLayout = screenWidth < 440;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(30, 20, 30, 0),
      actionsPadding: const EdgeInsets.fromLTRB(30, 10, 30, 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        widget.todo == null ? l10n.newTask : l10n.editTask,
        style: AppTheme.dialogTitleStyle(context),
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: dialogWidth,
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
              const SizedBox(height: 16),

              // Task Type Selector
              DialogInputRow(child: _buildTaskTypeSelector(context)),

              if (_taskType != TaskType.daily) ...[
                const SizedBox(height: 16),
                // Date Picker
                DialogInputRow(
                  child: _buildSchedulePicker(context, useVerticalDateLayout),
                ),
                const SizedBox(height: 16),
                // Grouping Controls
                DialogInputRow(child: _buildGroupingControls(context)),
              ],

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
                      final tagColor = tag.displayColor;
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
        Row(
          children: [
            if (widget.todo != null)
              TextButton(
                onPressed: () {
                  widget.onDelete?.call();
                  if (context.mounted) Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: Text(l10n.delete),
              ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: Text(l10n.cancel),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _isSubmitting
                  ? null
                  : () {
                      if (_titleController.text.isNotEmpty) {
                        _submit();
                      }
                    },
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
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
        ),
      ],
    );
  }

  Widget _buildTaskTypeSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildTaskTypeChip(
          context,
          TaskType.task,
          l10n.taskTypeTask,
          Icons.task_alt_outlined,
        ),
        _buildTaskTypeChip(
          context,
          TaskType.deadline,
          l10n.taskTypeDeadline,
          Icons.flag_outlined,
        ),
        _buildTaskTypeChip(
          context,
          TaskType.daily,
          l10n.taskTypeDaily,
          Icons.repeat_outlined,
        ),
      ],
    );
  }

  Widget _buildGroupingControls(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final parentOptions = _parentOptions();
    final selectedParentId = _validParentId(parentOptions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildGroupModeChip(
              context,
              TaskGroupMode.none,
              l10n.taskGroupModeSolo,
              Icons.radio_button_unchecked_rounded,
            ),
            _buildGroupModeChip(
              context,
              TaskGroupMode.subtasks,
              l10n.taskGroupModeSubtasks,
              Icons.account_tree_outlined,
            ),
            _buildGroupModeChip(
              context,
              TaskGroupMode.parallel,
              l10n.taskGroupModeParallel,
              Icons.view_week_outlined,
            ),
          ],
        ),
        if (_groupMode != TaskGroupMode.none) ...[
          const SizedBox(height: 12),
          _buildParentSelector(context, parentOptions, selectedParentId),
        ],
      ],
    );
  }

  Widget _buildParentSelector(
    BuildContext context,
    List<Todo> parentOptions,
    int? selectedParentId,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final secondaryColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final hasError = _parentRequiredError && selectedParentId == null;

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              l10n.parentTask,
              style: AppTheme.bodyMediumStyle(context, color: secondaryColor),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: secondaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasError ? theme.colorScheme.error : Colors.transparent,
              ),
            ),
            child: Theme(
              data: theme.copyWith(
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: selectedParentId,
                  focusColor: Colors.transparent,
                  hint: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      l10n.noParentTask,
                      style: AppTheme.accentBodyStyle(
                        context,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  isExpanded: true,
                  itemHeight: 52,
                  menuMaxHeight: 260,
                  borderRadius: BorderRadius.circular(8),
                  dropdownColor: theme.colorScheme.surface,
                  alignment: AlignmentDirectional.centerStart,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: secondaryColor,
                  ),
                  style: AppTheme.accentBodyStyle(
                    context,
                    color: theme.colorScheme.onSurface,
                  ),
                  items: [
                    ...parentOptions.map(
                      (todo) => DropdownMenuItem<int?>(
                        value: todo.id,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            todo.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                  selectedItemBuilder: (context) => [
                    ...parentOptions.map(
                      (todo) => Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            todo.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                  onChanged: parentOptions.isEmpty
                      ? null
                      : (value) {
                          setState(() {
                            _parentTodoId = value;
                            _parentRequiredError = false;
                          });
                        },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupModeChip(
    BuildContext context,
    TaskGroupMode value,
    String label,
    IconData icon,
  ) {
    final isSelected = _groupMode == value;
    final theme = Theme.of(context);
    final secondaryColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final color = isSelected ? theme.primaryColor : secondaryColor;

    return InkWell(
      onTap: () => _setGroupMode(value),
      borderRadius: BorderRadius.circular(8),
      hoverColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? theme.primaryColor
                : secondaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTheme.bodyStyle(context).merge(
                AppTheme.selectableLabelStyle(
                  context,
                  selected: isSelected,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulePicker(BuildContext context, bool useVerticalLayout) {
    final l10n = AppLocalizations.of(context)!;
    final minDate = DateTime.now().subtract(const Duration(days: 1));

    if (_taskType == TaskType.deadline) {
      return DialogDatePicker(
        label: l10n.dateTo,
        date: _ddl,
        firstDate: minDate,
        onSelect: (d) => setState(() => _ddl = d),
      );
    }

    final startPicker = DialogDatePicker(
      label: l10n.dateFrom,
      date: _startDate,
      firstDate: minDate,
      onSelect: (d) {
        setState(() {
          _startDate = d;
          if (d != null && _ddl != null && _ddl!.isBefore(d)) {
            _ddl = null;
          }
        });
      },
    );
    final endPicker = DialogDatePicker(
      label: l10n.dateTo,
      date: _ddl,
      firstDate: _startDate ?? minDate,
      onSelect: (d) => setState(() => _ddl = d),
    );

    if (useVerticalLayout) {
      return Column(
        children: [startPicker, const SizedBox(height: 12), endPicker],
      );
    }

    return Row(
      children: [
        Expanded(child: startPicker),
        const SizedBox(width: 12),
        Expanded(child: endPicker),
      ],
    );
  }

  Widget _buildTaskTypeChip(
    BuildContext context,
    TaskType value,
    String label,
    IconData icon,
  ) {
    final isSelected = _taskType == value;
    final theme = Theme.of(context);
    final secondaryColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final color = isSelected ? theme.primaryColor : secondaryColor;

    return InkWell(
      onTap: () => _setTaskType(value),
      borderRadius: BorderRadius.circular(8),
      hoverColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? theme.primaryColor
                : secondaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTheme.bodyStyle(context).merge(
                AppTheme.selectableLabelStyle(
                  context,
                  selected: isSelected,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setTaskType(TaskType value) {
    setState(() {
      _taskType = value;
      if (value == TaskType.daily) {
        _ddl = null;
        _parentTodoId = null;
        _groupMode = TaskGroupMode.none;
        _parentRequiredError = false;
      }
    });
  }

  void _setGroupMode(TaskGroupMode value) {
    setState(() {
      _groupMode = value;
      _parentRequiredError = false;
      if (value == TaskGroupMode.none) {
        _parentTodoId = null;
      }
    });
  }

  List<Todo> _parentOptions() {
    final currentId = widget.todo?.id;
    return widget.allTodos.where((todo) {
        if (todo.id == 0 || todo.taskType == TaskType.daily) {
          return false;
        }
        if (currentId != null && todo.id == currentId) {
          return false;
        }
        if (currentId != null && _isDescendantOf(todo.id, currentId)) {
          return false;
        }
        return true;
      }).toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }

  int? _validParentId([List<Todo>? options]) {
    final parentId = _parentTodoId;
    if (parentId == null) {
      return null;
    }
    final parentOptions = options ?? _parentOptions();
    return parentOptions.any((todo) => todo.id == parentId) ? parentId : null;
  }

  bool _isDescendantOf(int candidateId, int ancestorId) {
    final byId = {for (final todo in widget.allTodos) todo.id: todo};
    var cursor = byId[candidateId]?.parentTodoId;
    final seen = <int>{candidateId};

    while (cursor != null) {
      if (cursor == ancestorId) {
        return true;
      }
      if (!seen.add(cursor)) {
        return false;
      }
      cursor = byId[cursor]?.parentTodoId;
    }
    return false;
  }
}
