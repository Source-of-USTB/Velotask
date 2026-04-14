import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:velotask/models/tag.dart';
import 'package:velotask/models/todo.dart';
import 'package:velotask/models/todo_filter.dart';
import 'package:velotask/utils/priority_engine.dart';
import 'package:velotask/widgets/empty_state.dart';
import 'package:velotask/widgets/filter_section.dart';
import 'package:velotask/widgets/home_app_bar.dart';
import 'package:velotask/widgets/progress_header.dart';
import 'package:velotask/widgets/todo_item.dart';

class TodoListView extends StatefulWidget {
  final List<Todo> todos;
  final List<Tag> tags;
  final bool isLoading;
  final Function(Todo) onToggle;
  final Function(Todo) onDelete;
  final Function(Todo) onEdit;
  final VoidCallback onRefreshTags;
  final VoidCallback? onAIAction;

  const TodoListView({
    super.key,
    required this.todos,
    required this.tags,
    required this.isLoading,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    required this.onRefreshTags,
    this.onAIAction,
  });

  @override
  State<TodoListView> createState() => _TodoListViewState();
}

class _TodoListViewState extends State<TodoListView>
    with SingleTickerProviderStateMixin {
  TodoFilter _filter = TodoFilter.active;
  Tag? _filterTag;
  late final AnimationController _confettiController;
  bool _showConfetti = false;
  bool _hadAllCompleted = false;

  bool _isAllCompleted(List<Todo> list) {
    return list.isNotEmpty && list.every((todo) => todo.isCompleted);
  }

  @override
  void initState() {
    super.initState();
    _hadAllCompleted = _isAllCompleted(widget.todos);
    _confettiController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1600),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() {
              _showConfetti = false;
            });
          }
        });
  }

  @override
  void didUpdateWidget(covariant TodoListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_filterTag != null) {
      final stillExists = widget.tags.any((t) => t.id == _filterTag!.id);
      if (!stillExists) {
        setState(() {
          _filterTag = null;
        });
      }
    }
    final isAllCompletedNow = _isAllCompleted(widget.todos);
    if (isAllCompletedNow && !_hadAllCompleted) {
      _playConfetti();
    }
    _hadAllCompleted = isAllCompletedNow;
  }

  void _playConfetti() {
    setState(() {
      _showConfetti = true;
    });
    _confettiController.forward(from: 0);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  List<Todo> get _filteredTodos {
    List<Todo> result;

    // 1. Apply Status/Priority Filter
    switch (_filter) {
      case TodoFilter.active:
        result = widget.todos.where((t) => !t.isCompleted).toList();
        break;
      case TodoFilter.completed:
        result = widget.todos.where((t) => t.isCompleted).toList();
        break;
      case TodoFilter.highPriority:
        result = widget.todos
            .where((t) => !t.isCompleted && t.importance == 2)
            .toList();
        break;
      case TodoFilter.all:
        result = List<Todo>.from(widget.todos);
        break;
    }

    // 2. Apply Tag Filter (Intersection)
    if (_filterTag != null) {
      result = result
          .where((t) => t.tags.any((tag) => tag.id == _filterTag!.id))
          .toList();
    }

    return PriorityEngine.sortedTodos(result);
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredTodos;

    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            HomeAppBar(
              todos: widget.todos,
              onSettingsClosed: widget.onRefreshTags,
              onAIAction: widget.onAIAction,
            ),
            ProgressHeader(todos: widget.todos),
            FilterSection(
              currentFilter: _filter,
              currentTag: _filterTag,
              tags: widget.tags,
              onFilterChanged: (filter, tag) {
                setState(() {
                  _filter = filter;
                  _filterTag = tag;
                });
              },
            ),
            _buildMainContent(filteredList),
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
        if (_showConfetti)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _confettiController,
                builder: (context, child) {
                  return Opacity(
                    opacity: (1 - _confettiController.value * 0.85).clamp(
                      0.0,
                      1.0,
                    ),
                    child: CustomPaint(
                      painter: _ConfettiPainter(
                        progress: _confettiController.value,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMainContent(List<Todo> filteredList) {
    if (widget.isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (filteredList.isEmpty) {
      return const EmptyState();
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final todo = filteredList[index];
        return TweenAnimationBuilder<double>(
          key: ValueKey(todo.id),
          duration: Duration(milliseconds: 180 + (index * 8).clamp(0, 64)),
          curve: Curves.easeOutCubic,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            final opacity = 0.9 + (0.1 * value);
            return Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(0, 6 * (1 - value)),
                child: Transform.scale(
                  alignment: Alignment.center,
                  scale: 0.992 + (0.008 * value),
                  child: child,
                ),
              ),
            );
          },
          child: TodoItem(
            todo: todo,
            onToggle: () => widget.onToggle(todo),
            onDelete: () => widget.onDelete(todo),
            onEdit: () => widget.onEdit(todo),
          ),
        );
      }, childCount: filteredList.length),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;

  _ConfettiPainter({required this.progress});

  static const List<Color> _palette = [
    Color(0xFFFF5E57),
    Color(0xFFFFA801),
    Color(0xFF0BE881),
    Color(0xFF32C5FF),
    Color(0xFFB388FF),
    Color(0xFFFF7AD9),
  ];

  double _rand(int seed) {
    return (math.sin(seed * 12.9898) * 43758.5453).abs() % 1.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const pieceCount = 300;
    final t = progress.clamp(0.0, 1.0);
    final gravity = size.height * 1.3;
    final leftOrigin = Offset(-size.width * 0.03, size.height * 0.53);
    final rightOrigin = Offset(size.width * 1.03, size.height * 0.53);

    for (int i = 0; i < pieceCount; i++) {
      final sideLeft = i.isEven;
      final origin = sideLeft ? leftOrigin : rightOrigin;

      final delay = _rand(i + 301) * 0.24;
      final localT = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (localT <= 0) {
        continue;
      }

      final spread = (_rand(i + 17) - 0.5) * (math.pi / 4.2);
      final baseAngle = sideLeft ? -math.pi / 3.8 : -math.pi + math.pi / 3.8;
      final launchAngle = baseAngle + spread;

      final speed = size.height * (0.58 + _rand(i + 911) * 0.34);
      final vx = math.cos(launchAngle) * speed;
      final vy = math.sin(launchAngle) * speed;

      final x = origin.dx + vx * localT;
      final y = origin.dy + vy * localT + 0.5 * gravity * localT * localT;

      final velocityY = vy + gravity * localT;
      final travelAngle = math.atan2(velocityY, vx);
      final spin = (_rand(i + 77) - 0.5) * 2.4;
      final rotation = travelAngle + spin * localT * 2.2;

      final ribbonW = 8 + _rand(i + 51) * 10;
      final ribbonH = 3 + _rand(i + 149) * 3.5;
      final circleR = 2.2 + _rand(i + 181) * 2.8;
      final alpha = ((1 - localT) * 1.1).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = _palette[i % _palette.length].withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      if (i % 4 != 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: ribbonW,
              height: ribbonH,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, circleR, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
