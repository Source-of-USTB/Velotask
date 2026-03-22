import 'package:flutter/material.dart';
import 'package:velotask/models/todo.dart';
import 'package:velotask/theme/app_theme.dart';
import 'package:velotask/l10n/app_localizations.dart';

class TodoItem extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TodoItem({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  Color _importanceColor() {
    switch (todo.importance) {
      case 2:
        return AppTheme.highPriority;
      case 0:
        return AppTheme.lowPriority;
      default:
        return AppTheme.mediumPriority;
    }
  }

  String _formatDate(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final target = DateTime(date.year, date.month, date.day);
    if (target == today) return l10n.today;
    if (target == tomorrow) return l10n.tomorrow;
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  void _showDetail(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          todo.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: todo.description.isEmpty
            ? null
            : SingleChildScrollView(
                child: Text(
                  todo.description,
                  style: const TextStyle(fontSize: 15, height: 1.6),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onEdit();
            },
            child: Text(l10n.edit),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset globalPosition) {
    final l10n = AppLocalizations.of(context)!;
    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(globalPosition);
    final rect = RelativeRect.fromLTRB(
      globalPosition.dx,
      globalPosition.dy,
      globalPosition.dx + 1,
      globalPosition.dy + 1,
    );
    // ignore: unused_local_variable
    final _ = localPosition;

    showMenu<_MenuAction>(
      context: context,
      position: rect,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      items: [
        PopupMenuItem(
          value: _MenuAction.toggle,
          child: Row(
            children: [
              Icon(
                todo.isCompleted
                    ? Icons.radio_button_unchecked
                    : Icons.check_circle_outline,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                todo.isCompleted ? l10n.filterActive : l10n.completed,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: _MenuAction.edit,
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 18),
              const SizedBox(width: 10),
              Text(l10n.edit, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _MenuAction.delete,
          child: Row(
            children: [
              Icon(Icons.delete_outline,
                  size: 18, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 10),
              Text(
                l10n.delete,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((action) {
      if (action == null) return;
      switch (action) {
        case _MenuAction.toggle:
          onToggle();
        case _MenuAction.edit:
          onEdit();
        case _MenuAction.delete:
          onDelete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDone = todo.isCompleted;

    return GestureDetector(
      onTap: () => _showDetail(context),
      onSecondaryTapUp: (details) =>
          _showContextMenu(context, details.globalPosition),
      onLongPressStart: (details) =>
          _showContextMenu(context, details.globalPosition),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .secondary
                  .withValues(alpha: 0.1),
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 40,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDone
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).primaryColor,
                        width: 2,
                      ),
                      color: isDone
                          ? Theme.of(context).colorScheme.secondary
                          : Colors.transparent,
                    ),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isDone ? 1.0 : 0.0,
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Title + Tags
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (todo.tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: todo.tags.map((tag) {
                              Color tagColor = Colors.blue;
                              if (tag.color != null) {
                                try {
                                  tagColor = Color(
                                    int.parse(
                                        tag.color!.replaceAll('#', '0xFF')),
                                  );
                                } catch (_) {}
                              }
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: tagColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  tag.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: tagColor,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        decoration: isDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: isDone
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).primaryColor,
                        decorationColor:
                            Theme.of(context).colorScheme.secondary,
                      ),
                      child: Text(
                        todo.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // DDL
            SizedBox(
              width: 80,
              child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  final dateStr =
                      todo.ddl != null ? _formatDate(context, todo.ddl!) : '-';
                  final isUrgent =
                      dateStr == l10n.today || dateStr == l10n.tomorrow;
                  return Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 13,
                      color: isUrgent
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).colorScheme.secondary,
                      fontWeight:
                          isUrgent ? FontWeight.bold : FontWeight.normal,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ),

            // Priority badge
            SizedBox(
              width: 60,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _importanceColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    todo.importance == 2
                        ? AppLocalizations.of(context)!.priorityHigh
                        : todo.importance == 0
                            ? AppLocalizations.of(context)!.priorityLow
                            : AppLocalizations.of(context)!.priorityMed,
                    style: TextStyle(
                      fontSize: 10,
                      color: _importanceColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _MenuAction { toggle, edit, delete }
