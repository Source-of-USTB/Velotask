import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velotask/l10n/app_localizations.dart';

class AISettingsDialog extends StatefulWidget {
  const AISettingsDialog({super.key});

  @override
  State<AISettingsDialog> createState() => _AISettingsDialogState();
}

class _AISettingsDialogState extends State<AISettingsDialog> {
  bool _isTestingModel = false;
  final TextEditingController _aiBaseUrlController = TextEditingController();
  final TextEditingController _aiApiKeyController = TextEditingController();
  final TextEditingController _aiModelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAISettings();
  }

  @override
  void dispose() {
    _aiBaseUrlController.dispose();
    _aiApiKeyController.dispose();
    _aiModelController.dispose();
    super.dispose();
  }

  Future<void> _loadAISettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _aiBaseUrlController.text = prefs.getString('ai_base_url') ?? '';
        _aiApiKeyController.text = prefs.getString('ai_api_key') ?? '';
        _aiModelController.text =
            prefs.getString('ai_model') ?? 'gpt-3.5-turbo';
      });
    }
  }

  Future<void> _saveAISettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_base_url', _aiBaseUrlController.text.trim());
    await prefs.setString('ai_api_key', _aiApiKeyController.text.trim());
    await prefs.setString('ai_model', _aiModelController.text.trim());
  }

  Future<void> _testAIModelConfig(BuildContext dialogContext) async {
    final l10n = AppLocalizations.of(context)!;
    final rawBaseUrl = _aiBaseUrlController.text.trim();
    final apiKey = _aiApiKeyController.text.trim();
    final model = _aiModelController.text.trim();

    if (rawBaseUrl.isEmpty || apiKey.isEmpty || model.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.aiSettingsValidationError)));
      return;
    }

    setState(() {
      _isTestingModel = true;
    });

    final normalizedBaseUrl = rawBaseUrl.endsWith('/')
        ? rawBaseUrl.substring(0, rawBaseUrl.length - 1)
        : rawBaseUrl;
    final lowerBaseUrl = normalizedBaseUrl.toLowerCase();
    final uri = Uri.parse(
      lowerBaseUrl.endsWith('/chat/completions')
          ? normalizedBaseUrl
          : '$normalizedBaseUrl/chat/completions',
    );
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final baseBody = <String, dynamic>{
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content':
              'Return JSON only: {"ok":true,"provider":"string","model":"string"}',
        },
        {'role': 'user', 'content': '{"ping":"velotask"}'},
      ],
      'temperature': 0,
      'max_tokens': 48,
      'n': 1,
      'stream': false,
    };

    Future<http.Response> postWith(bool jsonMode) {
      final body = Map<String, dynamic>.from(baseBody);
      if (jsonMode) {
        body['response_format'] = {'type': 'json_object'};
      }
      return http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 12));
    }

    try {
      var response = await postWith(true);
      if (response.statusCode == 400) {
        final bodyText = utf8.decode(response.bodyBytes);
        final unsupportedResponseFormat =
            bodyText.contains('response_format') &&
            (bodyText.contains('unknown') ||
                bodyText.contains('Unrecognized') ||
                bodyText.contains('unsupported'));
        if (unsupportedResponseFormat) {
          response = await postWith(false);
        }
      }

      if (response.statusCode != 200) {
        throw Exception(
          'HTTP ${response.statusCode}: ${utf8.decode(response.bodyBytes)}',
        );
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic> ||
          decoded['choices'] is! List ||
          (decoded['choices'] as List).isEmpty) {
        throw const FormatException(
          'Invalid response format from model provider',
        );
      }

      if (!mounted) return;
      await _saveAISettings();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.aiTestSuccess)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${l10n.aiParseError}: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isTestingModel = false;
        });
      }
      if (dialogContext.mounted) {
        FocusScope.of(dialogContext).unfocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogWidth = screenWidth > 700 ? 560.0 : screenWidth - 40;
    final maxDialogBodyHeight = screenHeight * 0.68;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Text(l10n.aiSettings),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: maxDialogBodyHeight,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _aiBaseUrlController,
                decoration: InputDecoration(
                  labelText: l10n.aiBaseUrl,
                  hintText: 'https://api.openai.com/v1',
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _aiApiKeyController,
                decoration: InputDecoration(
                  labelText: l10n.aiApiKey,
                  hintText: 'sk-...',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _aiModelController,
                decoration: InputDecoration(
                  labelText: l10n.aiModel,
                  hintText: 'gpt-3.5-turbo',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton.icon(
          onPressed: _isTestingModel
              ? null
              : () => _testAIModelConfig(context),
          style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
          icon: _isTestingModel
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_circle_outline),
          label: Text(_isTestingModel ? l10n.aiProcessing : l10n.aiTestModel),
        ),
        TextButton(
          onPressed: () async {
            await _saveAISettings();
            if (!context.mounted) return;
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }
}
