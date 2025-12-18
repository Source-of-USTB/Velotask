import 'package:flutter/material.dart';
import 'package:velotask/models/tag.dart';
import 'package:velotask/models/todo_filter.dart';
import 'package:velotask/l10n/app_localizations.dart';

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
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildStatusChip(
                  context,
                  AppLocalizations.of(context)!.filterActive,
                  TodoFilter.active,
                ),
                const SizedBox(width: 8),
                _buildStatusChip(
                  context,
                  AppLocalizations.of(context)!.filterAll,
                  TodoFilter.all,
                ),
                const SizedBox(width: 8),
                _buildStatusChip(
                  context,
                  AppLocalizations.of(context)!.filterDone,
                  TodoFilter.completed,
                ),
                const SizedBox(width: 8),
                _buildStatusChip(
                  context,
                  AppLocalizations.of(context)!.filterEmergency,
                  TodoFilter.highPriority,
                ),
              ],
            ),
          ),

          // Tag Filters
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
          ] else
            const SizedBox(height: 16),
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

    return FilterChip(
      showCheckmark: false,
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onFilterChanged(filter, currentTag),
      backgroundColor: Colors.transparent,
      selectedColor: theme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? colorScheme.onPrimary : colorScheme.secondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected
              ? Colors.transparent
              : colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      visualDensity: VisualDensity.compact,
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
      label: Text(tag.name),
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }
}
