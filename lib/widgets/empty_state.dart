import 'package:flutter/material.dart';
import 'package:velotask/l10n/app_localizations.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noTasksFound,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.secondary.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
