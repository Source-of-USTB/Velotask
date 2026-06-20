import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velotask/l10n/app_localizations.dart';
import 'package:velotask/services/app_settings_controller.dart';
import 'package:velotask/theme/app_theme.dart';

class TimelineRangeDialog extends StatefulWidget {
  const TimelineRangeDialog({super.key});

  @override
  State<TimelineRangeDialog> createState() => _TimelineRangeDialogState();
}

class _TimelineRangeDialogState extends State<TimelineRangeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _pastMonthsController;
  late final TextEditingController _futureMonthsController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final range = AppSettingsController.timelineRangeNotifier.value;
    _pastMonthsController = TextEditingController(
      text: range.pastMonths.toString(),
    );
    _futureMonthsController = TextEditingController(
      text: range.futureMonths.toString(),
    );
  }

  @override
  void dispose() {
    _pastMonthsController.dispose();
    _futureMonthsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(
        l10n.timelineRange,
        style: AppTheme.dialogTitleStyle(context),
      ),
      content: _buildContent(l10n),
      actions: [
        _buildCancelButton(l10n),
        _buildSaveButton(l10n),
      ],
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    return SizedBox(
      width: 360,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMonthField(
              controller: _pastMonthsController,
              label: l10n.timelineMonthsBefore,
              l10n: l10n,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            _buildMonthField(
              controller: _futureMonthsController,
              label: l10n.timelineMonthsAfter,
              l10n: l10n,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthField({
    required TextEditingController controller,
    required String label,
    required AppLocalizations l10n,
    required TextInputAction textInputAction,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_isSaving,
      keyboardType: TextInputType.number,
      textInputAction: textInputAction,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        helperText: l10n.timelineRangeLimitHint(
          AppSettingsController.maxTimelineMonths,
        ),
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final months = int.tryParse(value ?? '');
        if (months == null ||
            months < 0 ||
            months > AppSettingsController.maxTimelineMonths) {
          return l10n.timelineRangeLimitHint(
            AppSettingsController.maxTimelineMonths,
          );
        }
        return null;
      },
    );
  }

  Widget _buildCancelButton(AppLocalizations l10n) {
    return TextButton(
      onPressed: _isSaving ? null : () => Navigator.pop(context),
      child: Text(l10n.cancel),
    );
  }

  Widget _buildSaveButton(AppLocalizations l10n) {
    return FilledButton(
      onPressed: _isSaving ? null : _save,
      child: _isSaving
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(l10n.save),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final pastMonths = int.parse(_pastMonthsController.text);
    final futureMonths = int.parse(_futureMonthsController.text);
    if (!AppSettingsController.isValidTimelineRange(
      pastMonths,
      futureMonths,
    )) {
      _formKey.currentState?.validate();
      return;
    }

    setState(() => _isSaving = true);
    await AppSettingsController.setTimelineRange(
      pastMonths: pastMonths,
      futureMonths: futureMonths,
    );

    if (mounted) Navigator.pop(context);
  }
}
