import 'package:flutter/material.dart';
import 'package:velotask/models/tag.dart';
import 'package:velotask/models/todo.dart';
import 'package:velotask/theme/app_theme.dart';
import 'package:velotask/l10n/app_localizations.dart';

class TodoItem extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final List<Tag>? visibleTags; // For testing or explicit tag display

  const TodoItem({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    this.visibleTags,
  });

  Color _getImportanceColor() {
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

    if (target == today) {
      return l10n.today;
    } else if (target == tomorrow) {
      return l10n.tomorrow;
    } else {
      return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDone = todo.isCompleted;

    return Dismissible(
      key: Key(todo.id.toString()),
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.secondary.withValues(alpha: 0.1),
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            // Checkbox Column (Fixed width)
            GestureDetector(
              onTap: onToggle,
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

            // Name Column (Expanded)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if ((visibleTags ?? todo.tags).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: (visibleTags ?? todo.tags).map((tag) {
                              Color tagColor = Colors.blue;
                              if (tag.color != null) {
                                try {
                                  tagColor = Color(
                                    int.parse(
                                      tag.color!.replaceAll('#', '0xFF'),
                                    ),
                                  );
                                } catch (_) {}
                              }
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
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
                    Row(
                      children: [
                        Expanded(
                          child: AnimatedDefaultTextStyle(
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
                              decorationColor: Theme.of(
                                context,
                              ).colorScheme.secondary,
                            ),
                            child: Text(
                              todo.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (todo.description.isNotEmpty)
                      Text(
                        todo.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.secondary
                              .withValues(
                                alpha: 0.8, // Increased contrast
                              ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),

            // DDL Column (Fixed width)
            SizedBox(
              width: 80,
              child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  final dateStr = todo.ddl != null
                      ? _formatDate(context, todo.ddl!)
                      : '-';
                  final isUrgent =
                      dateStr == l10n.today || dateStr == l10n.tomorrow;
                  return Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 13,
                      color: isUrgent
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).colorScheme.secondary,
                      fontWeight: isUrgent
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ),

            // Importance Column (Fixed width)
            SizedBox(
              width: 60,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getImportanceColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12), // Pill shape
                  ),
                  child: Text(
                    todo.importance == 2
                        ? AppLocalizations.of(context)!.priorityHigh
                        : todo.importance == 0
                        ? AppLocalizations.of(context)!.priorityLow
                        : AppLocalizations.of(context)!.priorityMed,
                    style: TextStyle(
                      fontSize: 10,
                      color: _getImportanceColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // Edit Button
            SizedBox(
              width: 40,
              child: IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: Theme.of(
                    context,
                  ).colorScheme.secondary.withValues(alpha: 0.4),
                ),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 20,
                hoverColor: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
