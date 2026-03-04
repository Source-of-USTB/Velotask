import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:velotask/l10n/app_localizations.dart';
import 'package:velotask/main.dart';
import 'package:velotask/screens/tags_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';
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
      appBar: AppBar(title: Text(l10n.settings)),
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
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
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
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.aiSettings),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _aiBaseUrlController,
              decoration: InputDecoration(
                labelText: l10n.aiBaseUrl,
                hintText: 'https://api.openai.com/v1',
                helperText: l10n.aiBaseUrlHelper,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _aiApiKeyController,
              decoration: InputDecoration(
                labelText: l10n.aiApiKey,
                hintText: 'sk-...',
                helperText: l10n.aiApiKeyHelper,
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _aiModelController,
              decoration: InputDecoration(
                labelText: l10n.aiModel,
                hintText: 'gpt-3.5-turbo',
                helperText: l10n.aiModelHelper,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () {
              _saveAISettings();
              Navigator.pop(context);
            },
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    );
  }
}
