import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velotask/l10n/app_localizations.dart';
import 'package:velotask/models/todo.dart';
import 'package:velotask/models/todo_hierarchy.dart';
import 'package:velotask/services/app_settings_controller.dart';
import 'package:velotask/theme/app_theme.dart';
import 'package:velotask/utils/constants.dart';
import 'package:velotask/widgets/timeline/gantt_chart.dart';
import 'package:velotask/widgets/timeline/timeline_task_row.dart';

class TimelineScreen extends StatefulWidget {
  final List<Todo> todos;
  final void Function(Todo task)? onTaskDoubleTap;

  const TimelineScreen({super.key, required this.todos, this.onTaskDoubleTap});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  static const double _baseDayWidth = 60.0;
  static const List<double> _zoomLevels = [0.25, 0.5, 1, 2, 4, 8, 16, 32];
  static const int _defaultZoomIndex = 2; // 1x = 60px/day

  late final ScrollController _headerCtrl;
  late final ScrollController _bodyCtrl;
  late DateTime _chartStart;
  late DateTime _chartEndExclusive;
  late int _totalDays;

  int _zoomIndex = _defaultZoomIndex;
  double get _dayWidth => _baseDayWidth * _zoomLevels[_zoomIndex];
  double get _totalWidth => _totalDays * _dayWidth;

  bool _syncing = false;
  bool _didAutoScroll = false;
  final Set<int> _collapsedTodoIds = {};
  late Timer _nowTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _updateChartRange();
    AppSettingsController.timelineRangeNotifier.addListener(
      _onTimelineRangeChanged,
    );

    _headerCtrl = ScrollController();
    _bodyCtrl = ScrollController();
    _bodyCtrl.addListener(_syncBody);
    _headerCtrl.addListener(_syncHeader);

    _nowTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  @override
  void dispose() {
    _nowTimer.cancel();
    AppSettingsController.timelineRangeNotifier.removeListener(
      _onTimelineRangeChanged,
    );
    _headerCtrl
      ..removeListener(_syncHeader)
      ..dispose();
    _bodyCtrl
      ..removeListener(_syncBody)
      ..dispose();
    super.dispose();
  }

  void _updateChartRange() {
    final now = DateTime.now();
    final range = AppSettingsController.timelineRangeNotifier.value;
    _chartStart = DateTime(now.year, now.month - range.pastMonths, 1);
    _chartEndExclusive = DateTime(
      now.year,
      now.month + range.futureMonths + 1,
      1,
    );
    _totalDays = _chartEndExclusive.difference(_chartStart).inDays;
  }

  void _onTimelineRangeChanged() {
    if (!mounted) return;

    setState(() {
      _updateChartRange();
      _didAutoScroll = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  void _syncBody() {
    if (_syncing || !_headerCtrl.hasClients) return;
    _syncing = true;
    _headerCtrl.jumpTo(_bodyCtrl.offset);
    _syncing = false;
  }

  void _syncHeader() {
    if (_syncing || !_bodyCtrl.hasClients) return;
    _syncing = true;
    _bodyCtrl.jumpTo(_headerCtrl.offset);
    _syncing = false;
  }

  void _scrollToToday() {
    if (!_bodyCtrl.hasClients) return;
    final now = DateTime.now();
    // Use minute-precision so the now-line lands at the same pixel
    // offset regardless of time-of-day. Matches _NowLinePainter's formula.
    final nowX = now.difference(_chartStart).inMinutes / 1440.0 * _dayWidth;
    final viewportW = _bodyCtrl.position.viewportDimension;
    final target = (nowX - viewportW * 0.15).clamp(
      0.0,
      _bodyCtrl.position.maxScrollExtent,
    );
    _bodyCtrl.jumpTo(target);
  }

  // -- Zoom via Ctrl/Cmd + scroll wheel -----------------------------------

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;

    final keys = HardwareKeyboard.instance;
    final isZoomKey = keys.isControlPressed || keys.isMetaPressed;
    if (!isZoomKey) return;

    final dy = event.scrollDelta.dy;
    if (dy == 0) return;

    final newIndex = dy > 0 ? _zoomIndex - 1 : _zoomIndex + 1;
    if (newIndex < 0 || newIndex >= _zoomLevels.length) return;

    final localX = event.localPosition.dx;
    final oldScrollOffset = _bodyCtrl.hasClients ? _bodyCtrl.offset : 0.0;
    final oldDayWidth = _dayWidth;

    // Cancel the scroll movement the outer ScrollView would apply
    if (_bodyCtrl.hasClients) {
      _bodyCtrl.jumpTo(oldScrollOffset);
    }

    setState(() {
      _zoomIndex = newIndex;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_bodyCtrl.hasClients) return;
      final dayAtCursor = (oldScrollOffset + localX) / oldDayWidth;
      final newOffset = dayAtCursor * _dayWidth - localX;
      final clamped = newOffset.clamp(0.0, _bodyCtrl.position.maxScrollExtent);
      _bodyCtrl.jumpTo(clamped);
    });
  }

  // ------------------------------------------------------------------------

  List<TodoHierarchyNode> _filteredTodoNodes() {
    if (widget.todos.isEmpty) return [];

    int compareTodos(Todo a, Todo b) {
      DateTime ka(Todo t) {
        if (t.taskType == TaskType.deadline) return t.ddl ?? farFutureDate;
        return t.startDate ?? t.createdAt ?? farFutureDate;
      }

      final byKey = ka(a).compareTo(ka(b));
      if (byKey != 0) return byKey;
      if (a.taskType == b.taskType && a.taskType != TaskType.deadline) {
        final endA = a.ddl ?? farFutureDate;
        final endB = b.ddl ?? farFutureDate;
        return endA.compareTo(endB);
      }
      return a.id.compareTo(b.id);
    }

    final nodes = _filterTimelineNodes(buildTodoHierarchy(widget.todos));
    sortTodoHierarchy(nodes, compareTodos);
    return nodes;
  }

  List<TodoHierarchyNode> _filterTimelineNodes(List<TodoHierarchyNode> nodes) {
    final result = <TodoHierarchyNode>[];
    for (final node in nodes) {
      final children = _filterTimelineNodes(node.children);
      final copy = TodoHierarchyNode(todo: node.todo, children: children);
      final range = _rangeForNode(copy);
      if (range != null && _rangeIntersectsChart(range)) {
        result.add(copy);
      }
    }
    return result;
  }

  List<TimelineRow> _timelineRows(List<TodoHierarchyNode> nodes) {
    final rows = <TimelineRow>[];
    for (final node in nodes) {
      _appendTimelineRows(rows, node, 0);
    }
    return rows;
  }

  void _appendTimelineRows(
    List<TimelineRow> rows,
    TodoHierarchyNode node,
    int depth,
  ) {
    final hasChildren = node.hasChildren;
    final isExpanded = hasChildren && !_collapsedTodoIds.contains(node.todo.id);
    final range = _rangeForNode(node);

    rows.add(
      TimelineRow(
        todos: [node.todo],
        depth: depth,
        isGroupHeader: hasChildren,
        isExpanded: isExpanded,
        childCount: node.descendantCount,
        completedChildCount: node.doneDescendantCount,
        effectiveStart: hasChildren ? range?.start : null,
        effectiveEnd: hasChildren ? range?.end : null,
      ),
    );

    if (!hasChildren || !isExpanded) {
      return;
    }

    final usesParallelLanes =
        node.todo.groupMode == TaskGroupMode.parallel ||
        node.children.any(
          (child) => child.todo.groupMode == TaskGroupMode.parallel,
        );

    if (usesParallelLanes) {
      final plainChildren = node.children
          .where((child) => !child.hasChildren)
          .toList();
      final nestedGroups = node.children
          .where((child) => child.hasChildren)
          .toList();

      for (final lane in _packParallelLanes(plainChildren)) {
        rows.add(
          TimelineRow(
            todos: lane.map((child) => child.todo).toList(),
            depth: depth + 1,
            isParallelLane: true,
          ),
        );
      }

      for (final child in nestedGroups) {
        _appendTimelineRows(rows, child, depth + 1);
      }
      return;
    }

    for (final child in node.children) {
      _appendTimelineRows(rows, child, depth + 1);
    }
  }

  List<List<TodoHierarchyNode>> _packParallelLanes(
    List<TodoHierarchyNode> nodes,
  ) {
    final items =
        nodes
            .map((node) {
              final range = _rangeForNode(node);
              return range == null ? null : _TimelineItem(node, range);
            })
            .whereType<_TimelineItem>()
            .toList()
          ..sort((a, b) {
            final byStart = a.range.start.compareTo(b.range.start);
            if (byStart != 0) return byStart;
            return a.range.end.compareTo(b.range.end);
          });

    final lanes = <List<TodoHierarchyNode>>[];
    final laneEnds = <DateTime>[];

    for (final item in items) {
      var placed = false;
      final itemEnd = item.range.safeEnd;
      for (var i = 0; i < lanes.length; i++) {
        if (!item.range.start.isBefore(laneEnds[i])) {
          lanes[i].add(item.node);
          laneEnds[i] = itemEnd;
          placed = true;
          break;
        }
      }
      if (!placed) {
        lanes.add([item.node]);
        laneEnds.add(itemEnd);
      }
    }

    return lanes;
  }

  _TaskRange? _rangeForNode(TodoHierarchyNode node) {
    if (node.todo.taskType == TaskType.daily) {
      return null;
    }

    DateTime? start = node.todo.taskType == TaskType.deadline
        ? _deadlineRangeStart(node.todo.ddl)
        : node.todo.startDate ?? node.todo.createdAt;
    DateTime? end = node.todo.ddl;

    for (final child in node.children) {
      final childRange = _rangeForNode(child);
      if (childRange == null) {
        continue;
      }
      start = _earlier(start, childRange.start);
      end = _later(end, childRange.end);
    }

    if (start == null && end != null) {
      start = end;
    }
    if (end == null && start != null) {
      end = start;
    }
    if (start == null || end == null) {
      return null;
    }
    if (end.isBefore(start)) {
      end = start;
    }
    return _TaskRange(start, end);
  }

  bool _rangeIntersectsChart(_TaskRange range) {
    return !range.end.isBefore(_chartStart) &&
        range.start.isBefore(_chartEndExclusive);
  }

  DateTime? _earlier(DateTime? a, DateTime b) {
    if (a == null || b.isBefore(a)) {
      return b;
    }
    return a;
  }

  DateTime? _later(DateTime? a, DateTime b) {
    if (a == null || b.isAfter(a)) {
      return b;
    }
    return a;
  }

  DateTime? _deadlineRangeStart(DateTime? ddl) {
    if (ddl == null) {
      return null;
    }
    final dayStart = DateTime(ddl.year, ddl.month, ddl.day);
    return dayStart.isBefore(ddl)
        ? dayStart
        : ddl.subtract(const Duration(days: 1));
  }

  void _toggleTimelineGroup(Todo todo) {
    setState(() {
      if (_collapsedTodoIds.contains(todo.id)) {
        _collapsedTodoIds.remove(todo.id);
      } else {
        _collapsedTodoIds.add(todo.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final timelineNodes = _filteredTodoNodes();
    final timelineRows = _timelineRows(timelineNodes);

    if (!_didAutoScroll && timelineRows.isNotEmpty && _bodyCtrl.hasClients) {
      _didAutoScroll = true;
      _scrollToToday();
    }

    return _buildTimeline(context, theme, l10n, timelineRows);
  }

  Widget _buildTimeline(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    List<TimelineRow> timelineRows,
  ) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.timeline.toUpperCase(),
          style: AppTheme.pageTitleStyle(
            context,
            color: theme.colorScheme.primary,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: l10n.today,
            onPressed: _scrollToToday,
            icon: const Icon(Icons.today_outlined),
          ),
        ],
      ),
      body: _buildTimelineBody(timelineRows),
    );
  }

  Widget _buildTimelineBody(List<TimelineRow> timelineRows) {
    return Listener(
      onPointerSignal: _onPointerSignal,
      child: GanttChart(
        rows: timelineRows,
        headerCtrl: _headerCtrl,
        bodyCtrl: _bodyCtrl,
        chartStart: _chartStart,
        totalDays: _totalDays,
        dayWidth: _dayWidth,
        totalWidth: _totalWidth,
        now: _now,
        onTaskDoubleTap: widget.onTaskDoubleTap,
        onToggleGroup: _toggleTimelineGroup,
      ),
    );
  }
}

class _TaskRange {
  final DateTime start;
  final DateTime end;

  const _TaskRange(this.start, this.end);

  DateTime get safeEnd =>
      end.isAfter(start) ? end : start.add(const Duration(minutes: 1));
}

class _TimelineItem {
  final TodoHierarchyNode node;
  final _TaskRange range;

  const _TimelineItem(this.node, this.range);
}
