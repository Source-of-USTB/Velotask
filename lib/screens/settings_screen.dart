import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:velotask/l10n/app_localizations.dart';
import 'package:velotask/main.dart';
import 'package:velotask/screens/tags_screen.dart';
import 'package:velotask/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';
  bool _isTestingModel = false;
  final TextEditingController _aiBaseUrlController = TextEditingController();
  final TextEditingController _aiApiKeyController = TextEditingController();
  final TextEditingController _aiModelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVersion();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.aiParseError}: ${e.toString().split('\n').first}',
          ),
        ),
      );
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

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = packageInfo.version;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _version = '1.0.0';
        });
      }
    }
  }

  Future<void> _setTheme(ThemeMode mode) async {
    themeNotifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.toString());
  }

  Future<void> _setLocale(Locale? locale) async {
    localeNotifier.value = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale != null) {
      await prefs.setString('locale', locale.languageCode);
    } else {
      await prefs.remove('locale');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.settings,
          style: AppTheme.pageTitleStyle(
            context,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, l10n.general),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, currentMode, child) {
              return ListTile(
                leading: const Icon(Icons.brightness_6_outlined),
                title: Text(l10n.theme),
                subtitle: Text(
                  currentMode == ThemeMode.system
                      ? l10n.systemDefault
                      : currentMode == ThemeMode.dark
                      ? l10n.darkMode
                      : l10n.lightMode,
                ),
                onTap: () => _showThemeDialog(context, currentMode),
              );
            },
          ),
          ValueListenableBuilder<Locale?>(
            valueListenable: localeNotifier,
            builder: (context, currentLocale, child) {
              return ListTile(
                leading: const Icon(Icons.language),
                title: Text(l10n.language),
                subtitle: Text(
                  currentLocale?.languageCode == 'zh'
                      ? l10n.chinese
                      : l10n.english,
                ),
                onTap: () => _showLanguageDialog(context, currentLocale),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(context, l10n.organization),
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: Text(l10n.manageTags),
            subtitle: Text(l10n.manageTagsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TagsScreen()),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(context, l10n.aiAssistant),
          ListTile(
            leading: const Icon(Icons.auto_awesome_outlined),
            title: Text(l10n.aiSettings),
            subtitle: Text(l10n.aiSettingsSubtitle),
            onTap: () => _showAISettingsDialog(context),
          ),
          const Divider(),
          _buildSectionHeader(context, l10n.about),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.version),
            subtitle: Text(_version),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: Text(l10n.sourceCode),
            subtitle: Text(l10n.viewOnGithub),
            onTap: () async {
              final uri = Uri.parse(
                'https://github.com/Source-of-USTB/Velotask',
              );
              final launched = await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
              if (!launched && context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.unableToOpenLink)));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: AppTheme.sectionTitleStyle(
          context,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, ThemeMode currentMode) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.selectTheme),
        children: [
          ListTile(
            title: Text(l10n.systemDefault),
            trailing: currentMode == ThemeMode.system
                ? const Icon(Icons.check)
                : null,
            onTap: () {
              _setTheme(ThemeMode.system);
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text(l10n.lightMode),
            trailing: currentMode == ThemeMode.light
                ? const Icon(Icons.check)
                : null,
            onTap: () {
              _setTheme(ThemeMode.light);
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text(l10n.darkMode),
            trailing: currentMode == ThemeMode.dark
                ? const Icon(Icons.check)
                : null,
            onTap: () {
              _setTheme(ThemeMode.dark);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, Locale? currentLocale) {
    final l10n = AppLocalizations.of(context)!;
    final effectiveLocale = currentLocale ?? const Locale('en');

    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.language),
        children: [
          ListTile(
            title: Text(l10n.english),
            trailing: effectiveLocale.languageCode == 'en'
                ? const Icon(Icons.check)
                : null,
            onTap: () {
              _setLocale(const Locale('en'));
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text(l10n.chinese),
            trailing: effectiveLocale.languageCode == 'zh'
                ? const Icon(Icons.check)
                : null,
            onTap: () {
              _setLocale(const Locale('zh'));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showAISettingsDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogWidth = screenWidth > 700 ? 560.0 : screenWidth - 40;
    final maxDialogBodyHeight = screenHeight * 0.68;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
      ),
    );
  }
}
