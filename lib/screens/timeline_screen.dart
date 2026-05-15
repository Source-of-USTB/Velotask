import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velotask/l10n/app_localizations.dart';
import 'package:velotask/models/todo.dart';
import 'package:velotask/theme/app_theme.dart';
import 'package:velotask/widgets/gantt_chart.dart';

class TimelineScreen extends StatefulWidget {
  final List<Todo> todos;
  final void Function(Todo task)? onTaskDoubleTap;

  const TimelineScreen({
    super.key,
    required this.todos,
    this.onTaskDoubleTap,
  });

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  static const double _baseDayWidth = 60.0;
  static const List<double> _zoomLevels = [0.25, 0.5, 1, 2, 4, 8, 16, 32];
  static const int _defaultZoomIndex = 2; // 1x = 60px/day
  static const int _yearsAroundToday = 2;

  late final ScrollController _headerCtrl;
  late final ScrollController _bodyCtrl;
  late final DateTime _chartStart;
  late final int _totalDays;

  int _zoomIndex = _defaultZoomIndex;
  double get _dayWidth => _baseDayWidth * _zoomLevels[_zoomIndex];
  double get _totalWidth => _totalDays * _dayWidth;

  bool _syncing = false;
  bool _didAutoScroll = false;
  late Timer _nowTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _chartStart = DateTime(now.year - _yearsAroundToday, 1, 1);
    final chartEnd = DateTime(now.year + _yearsAroundToday, 12, 31);
    _totalDays = chartEnd.difference(_chartStart).inDays;

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
    _headerCtrl
      ..removeListener(_syncHeader)
      ..dispose();
    _bodyCtrl
      ..removeListener(_syncBody)
      ..dispose();
    super.dispose();
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
    final oldScrollOffset =
        _bodyCtrl.hasClients ? _bodyCtrl.offset : 0.0;
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
      final clamped =
          newOffset.clamp(0.0, _bodyCtrl.position.maxScrollExtent);
      _bodyCtrl.jumpTo(clamped);
    });
  }

  // ------------------------------------------------------------------------

  List<Todo> _filteredTodos() {
    if (widget.todos.isEmpty) return [];

    final now = DateTime.now();
    final chartEnd = DateTime(now.year + _yearsAroundToday, 12, 31);

    return widget.todos.where((todo) {
      if (todo.taskType == TaskType.deadline) {
        final deadline = todo.ddl;
        if (deadline == null) return false;
        final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
        return !deadlineDay.isBefore(_chartStart) &&
            !deadlineDay.isAfter(chartEnd);
      }
      final start = DateTime(
        (todo.startDate ?? todo.createdAt ?? _chartStart).year,
        (todo.startDate ?? todo.createdAt ?? _chartStart).month,
        (todo.startDate ?? todo.createdAt ?? _chartStart).day,
      );
      final end = DateTime(
        (todo.ddl ?? start).year,
        (todo.ddl ?? start).month,
        (todo.ddl ?? start).day,
      );
      return !end.isBefore(_chartStart) && !start.isAfter(chartEnd);
    }).toList()
      ..sort((a, b) {
        DateTime ka(Todo t) {
          if (t.taskType == TaskType.deadline) return t.ddl ?? DateTime(9999);
          return t.startDate ?? t.createdAt ?? DateTime(9999);
        }
        final byKey = ka(a).compareTo(ka(b));
        if (byKey != 0) return byKey;
        if (a.taskType == b.taskType && a.taskType != TaskType.deadline) {
          final endA = a.ddl ?? DateTime(9999);
          final endB = b.ddl ?? DateTime(9999);
          return endA.compareTo(endB);
        }
        return a.id.compareTo(b.id);
      });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final timelineTasks = _filteredTodos();

    if (!_didAutoScroll && timelineTasks.isNotEmpty && _bodyCtrl.hasClients) {
      _didAutoScroll = true;
      _scrollToToday();
    }

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
      body: Listener(
        onPointerSignal: _onPointerSignal,
        child: GanttChart(
          tasks: timelineTasks,
          headerCtrl: _headerCtrl,
          bodyCtrl: _bodyCtrl,
          chartStart: _chartStart,
          totalDays: _totalDays,
          dayWidth: _dayWidth,
          totalWidth: _totalWidth,
          now: _now,
          onTaskDoubleTap: widget.onTaskDoubleTap,
        ),
      ),
    );
  }
}
