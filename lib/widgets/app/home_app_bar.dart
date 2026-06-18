import 'package:flutter/material.dart';
import 'package:velotask/l10n/app_localizations.dart';
import 'package:velotask/services/app_settings_controller.dart';
import 'package:velotask/theme/app_theme.dart';

class HomeAppBar extends StatelessWidget {
  final VoidCallback onAIAction;
  final VoidCallback onSettingsPressed;

  const HomeAppBar({
    super.key,
    required this.onAIAction,
    required this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      title: _buildTitle(context),
      actions: _buildActions(context),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
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
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    return [
      _buildAIButton(context),
      _buildSettingsButton(context),
      _buildThemeButton(),
      const SizedBox(width: 8),
    ];
  }

  Widget _buildAIButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return IconButton(
      icon: Icon(
        Icons.auto_awesome_outlined,
        color: Theme.of(context).primaryColor,
      ),
      tooltip: l10n.aiQuickAdd,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      onPressed: onAIAction,
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.settings_outlined,
        color: Theme.of(context).primaryColor,
      ),
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      onPressed: onSettingsPressed,
    );
  }

  Widget _buildThemeButton() {
    return ValueListenableBuilder<ThemeMode>(
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
            await _toggleTheme(mode);
          },
        );
      },
    );
  }

  Future<void> _toggleTheme(ThemeMode mode) async {
    final newMode = mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await AppSettingsController.setTheme(newMode);
  }
}
