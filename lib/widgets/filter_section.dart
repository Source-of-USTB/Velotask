import 'package:flutter/material.dart';
import 'package:velotask/l10n/app_localizations.dart';
import 'package:velotask/models/tag.dart';
import 'package:velotask/models/todo_filter.dart';

class FilterSection extends StatelessWidget {
  final TodoFilter currentFilter;
  final Tag? currentTag;
  final List<Tag> tags;
  final Function(TodoFilter, Tag?) onFilterChanged;

  const FilterSection({
    super.key,
    required this.currentFilter,
    this.currentTag,
    this.tags = const [],
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildStatusChip(context, l10n.filterActive, TodoFilter.active),
                const SizedBox(width: 8),
                _buildStatusChip(context, l10n.filterAll, TodoFilter.all),
                const SizedBox(width: 8),
                _buildStatusChip(
                  context,
                  l10n.filterDone,
                  TodoFilter.completed,
                ),
                const SizedBox(width: 8),
                _buildStatusChip(
                  context,
                  l10n.filterEmergency,
                  TodoFilter.highPriority,
                ),
              ],
            ),
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.label_outline_rounded,
                      size: 18,
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.5),
                    ),
                  ),
                  ...tags.map((tag) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildTagChip(context, tag),
                    );
                  }),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(
    BuildContext context,
    String label,
    TodoFilter filter,
  ) {
    final isSelected = currentFilter == filter;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ChoiceChip(
      showCheckmark: false,
      label: Text(label, softWrap: false, overflow: TextOverflow.visible),
      selected: isSelected,
      onSelected: (_) => onFilterChanged(filter, currentTag),
      backgroundColor: Colors.transparent,
      selectedColor: theme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? colorScheme.onPrimary : colorScheme.secondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
        height: 1.1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected
              ? Colors.transparent
              : colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildTagChip(BuildContext context, Tag tag) {
    final isSelected = currentTag?.id == tag.id;
    Color tagColor = Colors.blue;
    if (tag.color != null) {
      try {
        tagColor = Color(int.parse(tag.color!.replaceAll('#', '0xFF')));
      } catch (_) {}
    }

    return FilterChip(
      label: Text(tag.name, softWrap: false, overflow: TextOverflow.visible),
      selected: isSelected,
      onSelected: (bool selected) {
        onFilterChanged(currentFilter, selected ? tag : null);
      },
      backgroundColor: Colors.transparent,
      selectedColor: tagColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : tagColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
        height: 1.1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected
              ? Colors.transparent
              : tagColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      showCheckmark: false,
      labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
