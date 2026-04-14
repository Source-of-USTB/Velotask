import 'package:flutter/material.dart';
import 'package:velotask/l10n/app_localizations.dart';
import 'package:velotask/models/tag.dart';
import 'package:velotask/models/todo.dart';
import 'package:velotask/theme/app_theme.dart';
import 'package:velotask/utils/priority_engine.dart';

class TodoItem extends StatefulWidget {
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

  @override
  State<TodoItem> createState() => _TodoItemState();
}

class _TodoItemState extends State<TodoItem> {
  Color _getImportanceColor() {
    switch (widget.todo.importance) {
      case 2:
        return AppTheme.highPriority;
      case 0:
        return AppTheme.lowPriority;
      default:
        return AppTheme.mediumPriority;
    }
  }

  Color _urgencyColor(BuildContext context, UrgencyBand band) {
    final cs = Theme.of(context).colorScheme;
    return switch (band) {
      UrgencyBand.relaxed => cs.secondary,
      UrgencyBand.medium => AppTheme.mediumPriority,
      UrgencyBand.high => AppTheme.highPriority,
      UrgencyBand.impossible => cs.error,
    };
  }

  String _formatDate(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final target = DateTime(date.year, date.month, date.day);
    final timeStr =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    if (target == today) {
      return '${l10n.today} $timeStr';
    } else if (target == tomorrow) {
      return '${l10n.tomorrow} $timeStr';
    } else {
      return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} $timeStr';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDone = widget.todo.isCompleted;
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateStr = widget.todo.ddl != null
        ? _formatDate(context, widget.todo.ddl!)
        : '-';
    final isUrgent =
        widget.todo.ddl != null &&
        (() {
          final ddlDay = DateTime(
            widget.todo.ddl!.year,
            widget.todo.ddl!.month,
            widget.todo.ddl!.day,
          );
          return ddlDay == today || ddlDay == tomorrow;
        })();
    final statusLabel = isDone ? l10n.filterDone : l10n.filterActive;
    final priorityLabel = widget.todo.importance == 2
        ? l10n.priorityHigh
        : widget.todo.importance == 0
        ? l10n.priorityLow
        : l10n.priorityMed;
    final urgencyValue = PriorityEngine.urgency(widget.todo);
    final urgencyBand = PriorityEngine.urgencyBand(widget.todo);
    final urgencyColor = _urgencyColor(context, urgencyBand);
    final urgencyText = urgencyValue >= 9.99
        ? '9.99+'
        : urgencyValue.toStringAsFixed(2);

    return Dismissible(
      key: Key(widget.todo.id.toString()),
      background: Container(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.14),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Icon(
          isDone ? Icons.undo_rounded : Icons.done_rounded,
          color: Theme.of(context).primaryColor,
        ),
      ),
      secondaryBackground: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          widget.onToggle();
          return false;
        }
        return true;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          widget.onDelete();
        }
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        opacity: isDone ? 0.6 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isDone
                ? Theme.of(
                    context,
                  ).colorScheme.secondary.withValues(alpha: 0.04)
                : Colors.transparent,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((widget.visibleTags ?? widget.todo.tags).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: (widget.visibleTags ?? widget.todo.tags)
                                  .map((tag) {
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
                                        style: AppTheme.tinyBoldStyle(
                                          context,
                                          color: tagColor,
                                        ),
                                      ),
                                    );
                                  })
                                  .toList(),
                            ),
                          ),
                        ),
                      // 第一层：标题 + 状态
                      Row(
                        children: [
                          Expanded(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: AppTheme.bodyMediumStyle(context).copyWith(
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
                                widget.todo.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isDone)
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: Tween<double>(
                                      begin: 0.92,
                                      end: 1.0,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: Transform.rotate(
                                key: ValueKey(
                                  'stamp_${widget.todo.id}_$isDone',
                                ),
                                angle: -0.08,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                      width: 1.4,
                                    ),
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.error.withValues(alpha: 0.08),
                                  ),
                                  child: Text(
                                    statusLabel.toUpperCase(),
                                    style: AppTheme.stampStyle(
                                      context,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (widget.todo.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            widget.todo.description,
                            style: AppTheme.smallRegularStyle(context).copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.secondary.withValues(alpha: 0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(height: 8),
                      // 第二层：DDL + 优先级 + 编辑
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isUrgent
                                  ? Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.12)
                                  : Theme.of(context).colorScheme.secondary
                                        .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              dateStr,
                              style: AppTheme.dateChipStyle(
                                context,
                                urgent: isUrgent,
                                color: isUrgent
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getImportanceColor().withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              priorityLabel,
                              style: AppTheme.tinyBoldStyle(
                                context,
                                color: _getImportanceColor(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: urgencyColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'U: $urgencyText',
                              style: AppTheme.tinyBoldStyle(
                                context,
                                color: urgencyColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 44,
                            height: 44,
                            child: IconButton(
                              icon: Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondary.withValues(alpha: 0.5),
                              ),
                              onPressed: widget.onEdit,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                              ),
                              splashRadius: 22,
                              hoverColor: Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
