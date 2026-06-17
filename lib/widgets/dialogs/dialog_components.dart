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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
  final DateTime? firstDate;

  const DialogDatePicker({
    super.key,
    required this.label,
    required this.date,
    required this.onSelect,
    this.firstDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return InkWell(
      onTap: () => _pickDateTime(context),
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
            _dateLabel(context, secondaryColor),
            _dateValue(context),
            if (date != null) ...[
              const SizedBox(width: 4),
              _clearDateButton(context, secondaryColor),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final picked = await _pickDate(context);
    if (picked == null || !context.mounted) {
      return;
    }

    final initialTime = _initialTime();
    final pickedTime = await _pickTime(context, initialTime);
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
  }

  Future<DateTime?> _pickDate(BuildContext context) {
    final effectiveFirstDate = firstDate ?? DateTime(2000);
    final initialDate = date ?? DateTime.now();
    final validInitialDate = initialDate.isBefore(effectiveFirstDate)
        ? effectiveFirstDate
        : initialDate;

    return showDatePicker(
      context: context,
      initialDate: validInitialDate,
      firstDate: effectiveFirstDate,
      lastDate: DateTime(2100),
      builder: (context, child) => _datePickerTheme(context, child),
    );
  }

  Widget _datePickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        datePickerTheme: DatePickerThemeData(
          dayShape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      child: child!,
    );
  }

  TimeOfDay _initialTime() {
    final value = date;
    if (value == null) {
      return const TimeOfDay(hour: 23, minute: 59);
    }
    return TimeOfDay(hour: value.hour, minute: value.minute);
  }

  Future<TimeOfDay?> _pickTime(BuildContext context, TimeOfDay initialTime) {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) => _timePickerTheme(context, child),
    );
  }

  Widget _timePickerTheme(BuildContext context, Widget? child) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        timePickerTheme: TimePickerThemeData(
          backgroundColor: theme.colorScheme.surface,
          hourMinuteShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      child: child!,
    );
  }

  Widget _dateLabel(BuildContext context, Color secondaryColor) {
    return Text(
      label,
      style: AppTheme.smallRegularStyle(context, color: secondaryColor),
    );
  }

  Widget _dateValue(BuildContext context) {
    return Expanded(
      child: Text(
        _dateText(),
        textAlign: TextAlign.end,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.accentBodyStyle(
          context,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _clearDateButton(BuildContext context, Color secondaryColor) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: 20,
      height: 20,
      child: IconButton(
        tooltip: l10n.delete,
        onPressed: () => onSelect(null),
        icon: Icon(Icons.close_rounded, size: 16, color: secondaryColor),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      ),
    );
  }

  String _dateText() {
    final value = date;
    if (value == null) {
      return '--/-- --:--';
    }

    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.month}/${value.day} $hour:$minute';
  }
}
