import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velotask/l10n/app_localizations.dart';
import 'package:velotask/models/todo.dart';
import 'package:velotask/theme/app_theme.dart';
import 'package:velotask/utils/priority_engine.dart';

class DashboardScreen extends StatefulWidget {
  final List<Todo> todos;

  const DashboardScreen({super.key, required this.todos});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const String _displayNameKey = 'user_display_name';
  static const String _avatarImageKey = 'user_avatar_image_path';
  String? _displayName;
  String? _avatarImagePath;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadDisplayName();
  }

  Future<void> _loadDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    String? avatarPath = prefs.getString(_avatarImageKey);
    if (avatarPath != null && !await File(avatarPath).exists()) {
      avatarPath = null;
      await prefs.remove(_avatarImageKey);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _displayName = prefs.getString(_displayNameKey);
      _avatarImagePath = avatarPath;
    });
  }

  Future<void> _pickAvatarImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 88,
    );

    if (picked == null) {
      return;
    }

    final appDir = await getApplicationDocumentsDirectory();
    final avatarDir = Directory(
      '${appDir.path}${Platform.pathSeparator}avatar',
    );
    if (!await avatarDir.exists()) {
      await avatarDir.create(recursive: true);
    }
    final avatarPath =
        '${avatarDir.path}${Platform.pathSeparator}profile_avatar.jpg';
    await File(
      avatarPath,
    ).writeAsBytes(await picked.readAsBytes(), flush: true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_avatarImageKey, avatarPath);

    if (!mounted) {
      return;
    }
    setState(() {
      _avatarImagePath = avatarPath;
    });
  }

  Future<void> _editDisplayName() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: _effectiveName(l10n));

    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.dashboardEditNameTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(hintText: l10n.dashboardEditNameHint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );

    if (value == null || value.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_displayNameKey, value);

    if (!mounted) {
      return;
    }

    setState(() {
      _displayName = value;
    });
  }

  String _effectiveName(AppLocalizations l10n) {
    if (_displayName != null && _displayName!.trim().isNotEmpty) {
      return _displayName!.trim();
    }
    return l10n.dashboardDefaultUserName;
  }

  String _initialLetter(String name) {
    final normalized = name.trim();
    if (normalized.isEmpty) {
      return 'V';
    }
    return normalized.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final completed = widget.todos.where((todo) => todo.isCompleted).length;
    final highUrgent = widget.todos
        .where(
          (todo) =>
              !todo.isCompleted &&
              PriorityEngine.isHighUrgency(todo, allTodos: widget.todos),
        )
        .length;

    final statsTitle = l10n.dashboardTaskStats;
    final editNameText = l10n.dashboardEditName;
    final labelDone = l10n.dashboardCompletedTasks;
    final labelHighUrgency = l10n.dashboardHighUrgency;
    final displayName = _effectiveName(l10n);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            l10n.dashboard,
            style: AppTheme.pageTitleStyle(
              context,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.14),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _pickAvatarImage,
                            child: _avatarImagePath != null
                                ? ClipOval(
                                    child: Image.file(
                                      File(_avatarImagePath!),
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      _initialLetter(displayName),
                                      style: AppTheme.bodyStrongStyle(
                                        context,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).primaryColor,
                          ),
                          child: Icon(
                            Icons.photo_camera_outlined,
                            size: 12,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: AppTheme.bodyStrongStyle(context).copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: editNameText,
                  onPressed: _editDisplayName,
                  icon: const Icon(Icons.edit_outlined),
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.query_stats,
                      size: 20,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      statsTitle,
                      style: AppTheme.sectionTitleStyle(
                        context,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: labelDone,
                        value: completed.toString(),
                        icon: Icons.check_circle_outline,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        label: labelHighUrgency,
                        value: highUrgent.toString(),
                        icon: Icons.priority_high,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 8),
          Text(value, style: AppTheme.valueDisplayStyle(context, color: color)),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.captionStrongStyle(context).copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}
