import 'package:flutter/material.dart';
import 'package:velotask/l10n/app_localizations.dart';
import 'package:velotask/screens/settings_screen.dart';
import 'package:velotask/services/ai_service.dart';
import 'package:velotask/theme/app_theme.dart';
import 'package:velotask/utils/logger.dart';

class AIInputDialog extends StatefulWidget {
  final List<String> existingTags;

  const AIInputDialog({super.key, this.existingTags = const []});

  @override
  State<AIInputDialog> createState() => _AIInputDialogState();
}

class _AIInputDialogState extends State<AIInputDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isProcessing = false;
  String? _error;
  final AIService _aiService = AIService();
  static final _logger = AppLogger.getLogger('AIInputDialog');

  @override
  void dispose() {
    _controller.dispose();
    _aiService.dispose();
    super.dispose();
  }

  Future<void> _processInput() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final results = await _aiService.parseTasks(
        input,
        existingTags: widget.existingTags,
      );
      if (mounted) {
        Navigator.pop(context, results);
      }
    } catch (e) {
      _logger.severe('AI parsing failed', e);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _isProcessing = false;
          if (e.toString().contains('AI configuration missing')) {
            _error = 'config_missing';
          } else {
            _error = '${l10n.aiParseError}: $e';
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_error == 'config_missing') {
      return AlertDialog(
        title: Text(l10n.aiSettings),
        content: Text(l10n.aiSettingsSubtitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            child: Text(l10n.settings),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.blue),
          const SizedBox(width: 8),
          Text(l10n.aiQuickAdd, style: AppTheme.dialogTitleStyle(context)),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: l10n.aiInputHint,
                border: const OutlineInputBorder(),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _controller.clear();
                          });
                        },
                      )
                    : null,
              ),
              maxLines: 3,
              enabled: !_isProcessing,
              autofocus: true,
              onChanged: (_) => setState(() {}),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 100),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(10),
                child: SingleChildScrollView(
                  child: Text(
                    _error!,
                    style:
                        AppTheme.smallRegularStyle(context, color: Colors.red),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _processInput,
          child: _isProcessing
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(l10n.aiProcessing),
                  ],
                )
              : Text(l10n.aiSubmit),
        ),
      ],
    );
  }
}
