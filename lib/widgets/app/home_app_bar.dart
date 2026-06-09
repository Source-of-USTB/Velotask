import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velotask/l10n/app_localizations.dart';
import 'package:velotask/main.dart';
import 'package:velotask/models/todo.dart';
import 'package:velotask/screens/settings_screen.dart';
import 'package:velotask/theme/app_theme.dart';

class HomeAppBar extends StatelessWidget {
  final List<Todo> todos;
  final VoidCallback? onSettingsClosed;
  final VoidCallback? onAIAction;

  const HomeAppBar({
    super.key,
    required this.todos,
    this.onSettingsClosed,
    this.onAIAction,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            l10n.appName,
            style: AppTheme.brandTitleStyle(
              context,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.auto_awesome_outlined,
            color: Theme.of(context).primaryColor,
          ),
          tooltip: l10n.aiQuickAdd,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          onPressed: onAIAction,
        ),
        IconButton(
          icon: Icon(
            Icons.settings_outlined,
            color: Theme.of(context).primaryColor,
          ),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
            onSettingsClosed?.call();
          },
        ),
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, mode, child) {
            return IconButton(
              icon: Icon(
                mode == ThemeMode.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                color: Theme.of(context).primaryColor,
              ),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              onPressed: () async {
                final newMode = mode == ThemeMode.dark
                    ? ThemeMode.light
                    : ThemeMode.dark;
                themeNotifier.value = newMode;
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('theme_mode', newMode.toString());
              },
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
