import 'package:flutter/material.dart';
import 'package:velotask/models/todo.dart';
import 'package:velotask/theme/app_theme.dart';
import 'package:velotask/l10n/app_localizations.dart';

class ProgressHeader extends StatelessWidget {
  final List<Todo> todos;

  const ProgressHeader({super.key, required this.todos});

  @override
  Widget build(BuildContext context) {
    int completedCount = todos.where((todo) => todo.isCompleted).length;
    int totalCount = todos.length;
    double progress = totalCount == 0 ? 0 : completedCount / totalCount;

    if (totalCount == 0) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Background Track
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.1),
                    strokeWidth: 16,
                  ),
                ),
                // Progress
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: progress,
                    color: Theme.of(context).primaryColor,
                    backgroundColor: Colors.transparent,
                    strokeWidth: 16,
                    strokeCap: StrokeCap.butt,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${(progress * 100).toInt()}',
                          style: AppTheme.headerStyle(context).copyWith(
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).primaryColor,
                            height: 1.0,
                            letterSpacing: -2.0,
                          ),
                        ),
                        Text(
                          '%',
                          style: AppTheme.headerStyle(context).copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.completed,
                      style: AppTheme.headerStyle(context).copyWith(
                        fontSize: 11,
                        letterSpacing: 3.0,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
