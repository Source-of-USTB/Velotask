import 'package:flutter/material.dart';
import 'package:velotask/theme/app_theme.dart';

class ProgressCircle extends StatelessWidget {
  final double progress;
  final bool showCelebration;
  final String label;
  final double size;

  const ProgressCircle({
    super.key,
    required this.progress,
    this.showCelebration = false,
    required this.label,
    this.size = 140,
  });

  @override
  Widget build(BuildContext context) {
    final scale = size / 140;
    final strokeWidth = 16 * scale;

    return SizedBox(
      width: size,
      child: Column(
        children: [
          _buildProgressStack(context, scale, strokeWidth),
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
      ),
    );
  }

  Widget _buildProgressStack(
    BuildContext context,
    double scale,
    double strokeWidth,
  ) {
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildTrack(context, strokeWidth),
        _buildAnimatedProgress(context, strokeWidth),
        _buildAnimatedLabel(context, scale),
      ],
    );
  }

  Widget _buildTrack(BuildContext context, double strokeWidth) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        value: 1.0,
        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
        strokeWidth: strokeWidth,
      ),
    );
  }

  Widget _buildAnimatedProgress(BuildContext context, double strokeWidth) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
        tween: Tween<double>(begin: 0, end: progress),
        builder: (context, value, child) {
          return CircularProgressIndicator(
            value: value,
            color: Theme.of(context).primaryColor,
            backgroundColor: Colors.transparent,
            strokeWidth: strokeWidth,
            strokeCap: StrokeCap.butt,
          );
        },
      ),
    );
  }

  Widget _buildAnimatedLabel(BuildContext context, double scale) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: progress),
      builder: (context, value, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPercentLabel(context, value, scale),
            SizedBox(height: 4 * scale),
            _buildCaption(context, scale),
          ],
        );
      },
    );
  }

  Widget _buildPercentLabel(BuildContext context, double value, double scale) {
    return SizedBox(
      width: size * 0.72,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${(value * 100).toInt()}',
              style: AppTheme.progressValueStyle(
                context,
                color: Theme.of(context).primaryColor,
              ).copyWith(fontSize: 56 * scale, letterSpacing: 0),
            ),
            Text(
              '%',
              style: AppTheme.progressSymbolStyle(
                context,
                color: Theme.of(context).colorScheme.secondary,
              ).copyWith(fontSize: 24 * scale, letterSpacing: 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaption(BuildContext context, double scale) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTheme.progressCaptionStyle(
        context,
        color: Theme.of(context).colorScheme.secondary,
      ).copyWith(fontSize: 11 * scale, letterSpacing: 0),
    );
  }
}
