import 'package:flutter/material.dart';
import 'package:velotask/theme/app_theme.dart';

class ProgressCircle extends StatelessWidget {
  final double progress; // 0.0 – 1.0
  final bool showCelebration;
  final String label;

  const ProgressCircle({
    super.key,
    required this.progress,
    this.showCelebration = false,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
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
            SizedBox(
              width: 140,
              height: 140,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                tween: Tween<double>(begin: 0, end: progress),
                builder: (context, value, child) {
                  return CircularProgressIndicator(
                    value: value,
                    color: Theme.of(context).primaryColor,
                    backgroundColor: Colors.transparent,
                    strokeWidth: 16,
                    strokeCap: StrokeCap.butt,
                  );
                },
              ),
            ),
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0, end: progress),
              builder: (context, value, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${(value * 100).toInt()}',
                          style: AppTheme.progressValueStyle(
                            context,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        Text(
                          '%',
                          style: AppTheme.progressSymbolStyle(
                            context,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: AppTheme.progressCaptionStyle(
                        context,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeInCubic,
          child: showCelebration
              ? TweenAnimationBuilder<double>(
                  key: const ValueKey('all_done_celebration'),
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutBack,
                  tween: Tween<double>(begin: 0.85, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Text(
                    '🎉',
                    style: AppTheme.celebrationEmojiStyle(context),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('no_celebration')),
        ),
      ],
    );
  }
}
