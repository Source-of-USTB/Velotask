import 'package:flutter/material.dart';
import 'package:velotask/l10n/app_localizations.dart';
import 'package:velotask/theme/app_theme.dart';

class DialogInputRow extends StatelessWidget {
  final IconData? icon;
  final Widget child;
  final bool isInput;

  const DialogInputRow({
    super.key,
    this.icon,
    required this.child,
    this.isInput = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 20,
            color: Theme.of(
              context,
            ).colorScheme.secondary.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: isInput
              ? Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: child,
                )
              : child,
        ),
      ],
    );
  }
}

class PrioritySelector extends StatelessWidget {
  final int selectedPriority;
  final Function(int) onPriorityChanged;

  const PrioritySelector({
    super.key,
    required this.selectedPriority,
    required this.onPriorityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        _buildPriorityTag(context, 0, l10n.priorityLow, AppTheme.lowPriority),
        const SizedBox(width: 8),
        _buildPriorityTag(
          context,
          1,
          l10n.priorityMed,
          AppTheme.mediumPriority,
        ),
        const SizedBox(width: 8),
        _buildPriorityTag(context, 2, l10n.priorityHigh, AppTheme.highPriority),
      ],
    );
  }

  Widget _buildPriorityTag(
    BuildContext context,
    int value,
    String label,
    Color color,
  ) {
    final isSelected = selectedPriority == value;
    final theme = Theme.of(context);
    final secondaryColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return InkWell(
      onTap: () => onPriorityChanged(value),
      borderRadius: BorderRadius.circular(8),
      hoverColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : secondaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTheme.bodyStyle(context).merge(
                AppTheme.selectableLabelStyle(
                  context,
                  selected: isSelected,
                  color: isSelected ? color : secondaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DialogDatePicker extends StatelessWidget {
  final String label;
  final DateTime? date;
  final Function(DateTime?) onSelect;
  final bool isOptional;
  final DateTime? firstDate;
  final bool includeTime;

  const DialogDatePicker({
    super.key,
    required this.label,
    required this.date,
    required this.onSelect,
    this.isOptional = false,
    this.firstDate,
    this.includeTime = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: () async {
        final initialDate = date ?? DateTime.now();
        final effectiveFirstDate = firstDate ?? DateTime(2000);

        // Ensure initialDate is not before firstDate
        final validInitialDate = initialDate.isBefore(effectiveFirstDate)
            ? effectiveFirstDate
            : initialDate;

        final picked = await showDatePicker(
          context: context,
          initialDate: validInitialDate,
          firstDate: effectiveFirstDate,
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                datePickerTheme: DatePickerThemeData(
                  dayShape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked == null) {
          onSelect(null);
          return;
        }

        if (!includeTime) {
          onSelect(picked);
          return;
        }

        if (!context.mounted) return;

        final initialTime = date != null
            ? TimeOfDay(hour: date!.hour, minute: date!.minute)
            : const TimeOfDay(hour: 23, minute: 59);

        final pickedTime = await showTimePicker(
          context: context,
          initialTime: initialTime,
        );

        final effectiveTime = pickedTime ?? initialTime;
        onSelect(
          DateTime(
            picked.year,
            picked.month,
            picked.day,
            effectiveTime.hour,
            effectiveTime.minute,
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: secondaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTheme.smallRegularStyle(context, color: secondaryColor),
            ),
            Text(
              date == null
                  ? (isOptional
                        ? (includeTime ? '--/-- --:--' : '--/--')
                        : l10n.today)
                  : includeTime
                  ? '${date!.month}/${date!.day} ${date!.hour.toString().padLeft(2, '0')}:${date!.minute.toString().padLeft(2, '0')}'
                  : '${date!.month}/${date!.day}',
              style: AppTheme.accentBodyStyle(
                context,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
