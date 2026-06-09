import 'package:flutter/material.dart';
import 'package:velotask/l10n/app_localizations.dart';
import 'package:velotask/models/todo.dart';
import 'package:velotask/services/app_settings_controller.dart';
import 'package:velotask/theme/app_theme.dart';

class HomeAppBar extends StatelessWidget {
  final List<Todo> todos;
  final VoidCallback onAIAction;
  final VoidCallback onSettingsPressed;

  const HomeAppBar({
    super.key,
    required this.todos,
    required this.onAIAction,
    required this.onSettingsPressed,
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
          onPressed: onSettingsPressed,
        ),
        ValueListenableBuilder<ThemeMode>(
          valueListenable: AppSettingsController.themeNotifier,
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
                await AppSettingsController.setTheme(newMode);
              },
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
