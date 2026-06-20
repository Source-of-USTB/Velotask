import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:velotask/models/todo.dart';
import 'package:velotask/services/color_config_manager.dart';
import 'package:velotask/theme/app_theme.dart';
import 'package:velotask/widgets/timeline/timeline_layout.dart';

class TimelineRow {
  final List<Todo> todos;
  final int depth;
  final bool isGroupHeader;
  final bool isParallelLane;
  final String? parallelPlan;
  final bool isExpanded;
  final int childCount;
  final int completedChildCount;
  final DateTime? effectiveStart;
  final DateTime? effectiveEnd;

  const TimelineRow({
    required this.todos,
    this.depth = 0,
    this.isGroupHeader = false,
    this.isParallelLane = false,
    this.parallelPlan,
    this.isExpanded = false,
    this.childCount = 0,
    this.completedChildCount = 0,
    this.effectiveStart,
    this.effectiveEnd,
  });

  Todo get primaryTodo => todos.first;
}

class TimelineTaskRow extends StatelessWidget {
  final TimelineRow row;
  final void Function(Todo)? onDoubleTap;
  final void Function(Todo)? onToggleGroup;

  static const double rowHeight = 52.0;
  static const double _barHeight = 34.0;
  static const double _laneBarHeight = 28.0;
  static const double _barPadding = (rowHeight - _barHeight) / 2;
  static const double _laneBarPadding = (rowHeight - _laneBarHeight) / 2;
  static const double _triangleHeight = _barHeight;
  static const double _triangleWidth = _barHeight * 0.7;
  static const double _triangleTop = (rowHeight - _triangleHeight) / 2;

  const TimelineTaskRow({
    super.key,
    required this.row,
    this.onDoubleTap,
    this.onToggleGroup,
  });

  @override
  Widget build(BuildContext context) {
    final layout = TimelineLayout.of(context);
    final p = ColorConfigManager.instance.activePreset!;
    final b = Theme.of(context).brightness;

    return RepaintBoundary(
      child: SizedBox(
        height: rowHeight,
        width: layout.totalWidth,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Divider(
                height: 1,
                color: p.colorByKey('ganttRowDivider', b),
              ),
            ),
            if (row.depth > 0)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: (row.depth * 8).toDouble(),
                child: ColoredBox(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.04),
                ),
              ),
            for (final todo in row.todos) _buildTaskPosition(context, todo),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskPosition(BuildContext context, Todo todo) {
    if (_usesDeadlineMarker(todo)) {
      return _buildDeadlinePosition(context, todo);
    }
    return _buildRangePosition(context, todo);
  }

  bool _usesDeadlineMarker(Todo todo) {
    return todo.taskType == TaskType.deadline &&
        !row.isGroupHeader &&
        row.effectiveStart == null &&
        row.effectiveEnd == null;
  }

  Color _getTaskColor(Todo todo) {
    switch (todo.importance) {
      case 2:
        return AppTheme.highPriority;
      case 0:
        return AppTheme.lowPriority;
      default:
        return AppTheme.mediumPriority;
    }
  }

  Widget _buildDeadlinePosition(BuildContext context, Todo todo) {
    final layout = TimelineLayout.of(context);
    final p = ColorConfigManager.instance.activePreset!;
    final b = Theme.of(context).brightness;
    final color = _getTaskColor(todo);
    const minutesPerDay = 1440.0;

    final ddl = todo.ddl;
    if (ddl == null) {
      return const SizedBox.shrink();
    }

    final endMinutes = ddl.difference(layout.chartStart).inMinutes;
    final x = (endMinutes / minutesPerDay * layout.dayWidth).clamp(
      0.0,
      layout.totalWidth,
    );

    return Positioned(
      left: x - _triangleWidth / 2,
      top: _triangleTop,
      child: GestureDetector(
        onDoubleTap: () => onDoubleTap?.call(todo),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                size: const Size(_triangleWidth, _triangleHeight),
                painter: _TrianglePainter(color: color, shadowAlpha: 0.3),
              ),
              const SizedBox(width: 6),
              Text(
                todo.title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: p.colorByKey('homeBodyText', b),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRangePosition(BuildContext context, Todo todo) {
    final layout = TimelineLayout.of(context);
    final p = ColorConfigManager.instance.activePreset!;
    final b = Theme.of(context).brightness;
    final color = _getTaskColor(todo);
    const minutesPerDay = 1440.0;

    final start = _effectiveStart(todo);
    final end = _effectiveEnd(todo, start);
    if (start == null || end == null) {
      return const SizedBox.shrink();
    }

    final safeEnd = end.isAfter(start)
        ? end
        : start.add(const Duration(minutes: 1));
    final startMinutes = start.difference(layout.chartStart).inMinutes;
    final left = (startMinutes / minutesPerDay * layout.dayWidth).clamp(
      0.0,
      layout.totalWidth,
    );
    final durationMinutes = safeEnd.difference(start).inMinutes;
    final minWidth = layout.dayWidth / minutesPerDay;
    final barWidth = (durationMinutes / minutesPerDay * layout.dayWidth).clamp(
      minWidth,
      layout.totalWidth - left,
    );
    final barHeight = row.isParallelLane ? _laneBarHeight : _barHeight;
    final barTop = row.isParallelLane ? _laneBarPadding : _barPadding;

    return Positioned(
      left: left,
      top: barTop,
      width: barWidth,
      height: barHeight,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: row.isGroupHeader ? 0.18 : 0.25),
              blurRadius: row.isGroupHeader ? 3 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: row.isGroupHeader ? color.withValues(alpha: 0.86) : color,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.hardEdge,
          child: _BarHoverHighlight(
            child: _TaskBar(
              todo: todo,
              textColor: p.colorByKey('ganttTaskText', b),
              isGroupHeader: row.isGroupHeader,
              isExpanded: row.isExpanded,
              childCount: row.childCount,
              completedChildCount: row.completedChildCount,
              onToggleExpanded: row.isGroupHeader && row.childCount > 0
                  ? () => onToggleGroup?.call(row.primaryTodo)
                  : null,
              onDoubleTap: () => onDoubleTap?.call(todo),
            ),
          ),
        ),
      ),
    );
  }

  DateTime? _effectiveStart(Todo todo) {
    if (row.isGroupHeader && todo.id == row.primaryTodo.id) {
      return row.effectiveStart ?? todo.startDate ?? todo.createdAt ?? todo.ddl;
    }
    if (todo.taskType == TaskType.deadline) {
      return todo.ddl;
    }
    return todo.startDate ?? todo.createdAt;
  }

  DateTime? _effectiveEnd(Todo todo, DateTime? start) {
    if (row.isGroupHeader && todo.id == row.primaryTodo.id) {
      return row.effectiveEnd ?? todo.ddl ?? start;
    }
    return todo.ddl;
  }
}

class _TaskBar extends StatelessWidget {
  final Todo todo;
  final Color textColor;
  final bool isGroupHeader;
  final bool isExpanded;
  final int childCount;
  final int completedChildCount;
  final VoidCallback? onToggleExpanded;
  final VoidCallback? onDoubleTap;

  const _TaskBar({
    required this.todo,
    required this.textColor,
    required this.isGroupHeader,
    required this.isExpanded,
    required this.childCount,
    required this.completedChildCount,
    required this.onToggleExpanded,
    required this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = todo.isCompleted;
    return Opacity(
      opacity: isDone ? 0.45 : 1.0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._buildExpandButton(),
          Expanded(
            child: _ResponsiveDoubleTapInkWell(
              onDoubleTap: onDoubleTap,
              child: Container(
                padding: EdgeInsets.only(
                  left: onToggleExpanded == null ? 8 : 0,
                  right: 8,
                ),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    ..._buildCompletionStatus(isDone),
                    _buildTitle(),
                    ..._buildGroupSummary(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildExpandButton() {
    if (onToggleExpanded == null) {
      return const [];
    }

    return [
      Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: IconButton(
              onPressed: onToggleExpanded,
              icon: AnimatedRotation(
                turns: isExpanded ? 0.25 : 0.0,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: textColor,
                  size: 18,
                ),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              splashRadius: 16,
            ),
          ),
        ),
      ),
      const SizedBox(width: 2),
    ];
  }

  List<Widget> _buildCompletionStatus(bool isDone) {
    if (onToggleExpanded != null || !isDone) {
      return const [];
    }

    return [
      Icon(Icons.check, color: textColor, size: 14),
      const SizedBox(width: 4),
    ];
  }

  Widget _buildTitle() {
    return Expanded(
      child: Text(
        todo.title,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  List<Widget> _buildGroupSummary() {
    if (!isGroupHeader || childCount == 0) {
      return const [];
    }

    return [
      const SizedBox(width: 6),
      Icon(
        todo.groupMode == TaskGroupMode.parallel
            ? Icons.view_week_outlined
            : Icons.account_tree_outlined,
        color: textColor.withValues(alpha: 0.86),
        size: 13,
      ),
      const SizedBox(width: 3),
      Text(
        '$completedChildCount/$childCount',
        style: TextStyle(
          color: textColor.withValues(alpha: 0.9),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    ];
  }
}

class _ResponsiveDoubleTapInkWell extends StatefulWidget {
  final VoidCallback? onDoubleTap;
  final Widget child;

  const _ResponsiveDoubleTapInkWell({
    required this.onDoubleTap,
    required this.child,
  });

  @override
  State<_ResponsiveDoubleTapInkWell> createState() =>
      _ResponsiveDoubleTapInkWellState();
}

class _ResponsiveDoubleTapInkWellState
    extends State<_ResponsiveDoubleTapInkWell> {
  DateTime? _lastTapTime;
  Offset? _lastTapPosition;
  Offset? _currentTapPosition;

  void _handleTapDown(TapDownDetails details) {
    _currentTapPosition = details.globalPosition;
  }

  void _handleTap() {
    final now = DateTime.now();
    final lastTime = _lastTapTime;
    final lastPosition = _lastTapPosition;
    final currentPosition = _currentTapPosition;
    final isDoubleTap =
        lastTime != null &&
        currentPosition != null &&
        lastPosition != null &&
        now.difference(lastTime) <= kDoubleTapTimeout &&
        (currentPosition - lastPosition).distance <= kDoubleTapSlop;

    if (isDoubleTap) {
      _lastTapTime = null;
      _lastTapPosition = null;
      widget.onDoubleTap?.call();
      return;
    }

    _lastTapTime = now;
    _lastTapPosition = currentPosition;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      radius: 150,
      mouseCursor: SystemMouseCursors.click,
      onTapDown: widget.onDoubleTap == null ? null : _handleTapDown,
      onTap: widget.onDoubleTap == null ? null : _handleTap,
      hoverColor: Colors.transparent,
      highlightColor: Colors.white.withValues(alpha: 0.1),
      splashColor: Colors.white.withValues(alpha: 0.2),
      child: widget.child,
    );
  }
}

class _BarHoverHighlight extends StatefulWidget {
  final Widget child;

  const _BarHoverHighlight({required this.child});

  @override
  State<_BarHoverHighlight> createState() => _BarHoverHighlightState();
}

class _BarHoverHighlightState extends State<_BarHoverHighlight> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Ink(
        color: _isHovered
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.transparent,
        child: widget.child,
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  final double shadowAlpha;
  const _TrianglePainter({required this.color, this.shadowAlpha = 0.3});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final shadowPath = path.shift(const Offset(0, 2));
    canvas.drawPath(
      shadowPath,
      Paint()..color = color.withValues(alpha: shadowAlpha),
    );
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter old) =>
      old.color != color || old.shadowAlpha != shadowAlpha;
}
