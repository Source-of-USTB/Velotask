import 'package:flutter/material.dart';
import 'package:velotask/models/tag.dart';
import 'package:velotask/models/todo.dart';
import 'package:velotask/models/todo_filter.dart';
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

  const TodoListView({
    super.key,
    required this.todos,
    required this.tags,
    required this.isLoading,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    required this.onRefreshTags,
  });

  @override
  State<TodoListView> createState() => _TodoListViewState();
}

class _TodoListViewState extends State<TodoListView> {
  TodoFilter _filter = TodoFilter.active;
  Tag? _filterTag;

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
        result = widget.todos;
        break;
    }

    // 2. Apply Tag Filter (Intersection)
    if (_filterTag != null) {
      result = result
          .where((t) => t.tags.any((tag) => tag.id == _filterTag!.id))
          .toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredTodos;

    return CustomScrollView(
      slivers: [
        HomeAppBar(todos: widget.todos, onSettingsClosed: widget.onRefreshTags),
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
        if (widget.isLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (filteredList.isEmpty)
          const EmptyState()
        else
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final todo = filteredList[index];
              return TodoItem(
                todo: todo,
                onToggle: () => widget.onToggle(todo),
                onDelete: () => widget.onDelete(todo),
                onEdit: () => widget.onEdit(todo),
              );
            }, childCount: filteredList.length),
          ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }
}
