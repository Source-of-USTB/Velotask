import 'package:flutter/material.dart';
import 'package:velotask/l10n/app_localizations.dart';
import 'package:velotask/models/tag.dart';
import 'package:velotask/models/todo.dart';
import 'package:velotask/screens/dashboard_screen.dart';
import 'package:velotask/screens/timeline_screen.dart';
import 'package:velotask/screens/todo_list_view.dart';
import 'package:velotask/services/ai_service.dart';
import 'package:velotask/services/notification_service.dart';
import 'package:velotask/services/todo_storage.dart';
import 'package:velotask/utils/logger.dart';
import 'package:velotask/widgets/add_todo_dialog.dart';
import 'package:velotask/widgets/ai_input_dialog.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  List<Todo> todos = [];
  List<Tag> tags = [];
  bool _isLoading = true;
  final TodoStorage _storage = TodoStorage();
  final AIService _aiService = AIService();
  final NotificationService _notificationService = NotificationService();
  static final Logger _logger = AppLogger.getLogger('MainScreen');

  @override
  void initState() {
    super.initState();
    _logger.info('MainScreen initialized');
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncNotifications();
    });
  }

  @override
  void dispose() {
    _aiService.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      await Future.wait([_loadTodos(), _loadTags()]);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        await _syncNotifications();
      }
    } catch (e) {
      _logger.severe('Failed to load data', e);
    }
  }

  Future<void> _syncNotifications() async {
    if (!mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return;
    }
    await _notificationService.syncForTodos(todos, l10n);
  }

  Future<void> _loadTags() async {
    try {
      final loadedTags = await _storage.loadTags();
      if (mounted) {
        setState(() {
          tags = loadedTags;
        });
      }
    } catch (e) {
      _logger.severe('Failed to load tags', e);
    }
  }

  Future<void> _loadTodos() async {
    try {
      final loadedTodos = await _storage.loadTodos();
      if (mounted) {
        setState(() {
          todos = loadedTodos;
        });
      }
    } catch (e) {
      _logger.severe('Failed to load todos', e);
    }
  }

  Future<void> _addTodo(
    String title,
    String desc,
    DateTime? startDate,
    DateTime? ddl,
    int importance,
    List<Tag> tags, {
    double? presetEffortHours,
  }) async {
    if (title.isEmpty) return;

    final estimatedEffortHours =
        presetEffortHours ??
        await _aiService.estimateEffortHours(
          title: title,
          description: desc,
          importance: importance,
          startDate: startDate,
          ddl: ddl,
        );

    final newTodo = Todo(
      title: title,
      description: desc,
      startDate: startDate,
      ddl: ddl,
      importance: importance,
      estimatedEffortHours: estimatedEffortHours,
    );
    newTodo.tags.addAll(tags);

    await _storage.addTodo(newTodo);
    if (mounted) {
      setState(() {
        todos.add(newTodo);
      });
      await _syncNotifications();
    }
  }

  Future<void> _deleteTodo(Todo todo) async {
    await _storage.deleteTodo(todo.id);
    if (mounted) {
      setState(() {
        todos.removeWhere((t) => t.id == todo.id);
      });
      await _syncNotifications();
    }
  }

  Future<void> _toggleTodo(Todo todo) async {
    final updatedTodo = todo.copyWith(isCompleted: !todo.isCompleted);
    // Preserve tags to prevent flickering and data loss
    updatedTodo.tags.addAll(todo.tags);

    if (mounted) {
      setState(() {
        final index = todos.indexWhere((t) => t.id == todo.id);
        if (index != -1) {
          todos[index] = updatedTodo;
        }
      });
    }
    // No need to save links when just toggling completion status
    await _storage.updateTodo(updatedTodo, saveLinks: false);
    await _syncNotifications();
  }

  Future<void> _addTodosFromAI(List<AIParseResult> results) async {
    final filtered = results.where((r) => r.title.trim().isNotEmpty).toList();
    if (filtered.isEmpty) return;

    final tagByName = {
      for (final tag in tags) tag.name.toLowerCase(): tag,
    };

    var tagsAdded = false;
    for (final result in filtered) {
      for (final rawName in result.tags) {
        final name = rawName.trim();
        if (name.isEmpty) continue;
        final key = name.toLowerCase();
        if (tagByName.containsKey(key)) continue;

        final newTag = Tag(name: name);
        try {
          await _storage.addTag(newTag);
          tagByName[key] = newTag;
          tagsAdded = true;
        } catch (_) {
          // If tag exists concurrently, we'll refresh after loop.
          tagsAdded = true;
        }
      }
    }

    if (tagsAdded) {
      await _loadTags();
      tagByName
        ..clear()
        ..addEntries(tags.map((t) => MapEntry(t.name.toLowerCase(), t)));
    }

    final newTodos = <Todo>[];
    for (final result in filtered) {
      final todo = Todo(
        title: result.title.trim(),
        description: result.description.trim(),
        startDate: result.startDate,
        ddl: result.ddl,
        importance: result.importance,
        estimatedEffortHours: result.estimatedEffortHours,
      );

      final resolvedTags = result.tags
          .map((name) => tagByName[name.toLowerCase()])
          .whereType<Tag>()
          .toList();
      todo.tags.addAll(resolvedTags);

      await _storage.addTodo(todo);
      newTodos.add(todo);
    }

    if (mounted) {
      setState(() {
        todos.addAll(newTodos);
      });
      await _syncNotifications();
    }
  }

  Future<void> _editTodo(Todo todo) async {
    showDialog(
      context: context,
      builder: (context) => AddTodoDialog(
        todo: todo,
        onAdd: (title, desc, startDate, ddl, importance, tags) async {
          final estimatedEffortHours = await _aiService.estimateEffortHours(
            title: title,
            description: desc,
            importance: importance,
            startDate: startDate,
            ddl: ddl,
          );

          final updatedTodo = todo.copyWith(
            title: title,
            description: desc,
            startDate: startDate,
            ddl: ddl,
            importance: importance,
            estimatedEffortHours:
                estimatedEffortHours ?? todo.estimatedEffortHours,
          );
          updatedTodo.tags.clear();
          updatedTodo.tags.addAll(tags);

          if (mounted) {
            setState(() {
              final index = todos.indexWhere((t) => t.id == todo.id);
              if (index != -1) {
                todos[index] = updatedTodo;
              }
            });
          }
          await _storage.updateTodo(updatedTodo);
          await _syncNotifications();
        },
      ),
    );
  }

  void _showAddTodoDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTodoDialog(onAdd: _addTodo),
    );
  }

  Future<void> _showAIInputDialog() async {
    final results = await showDialog<List<AIParseResult>>(
      context: context,
      builder: (context) =>
          AIInputDialog(existingTags: tags.map((t) => t.name).toList()),
    );

    if (results != null && mounted) {
      await _addTodosFromAI(results);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.02),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _selectedIndex == 0
            ? TodoListView(
                key: const ValueKey('todo_list'),
                todos: todos,
                tags: tags,
                isLoading: _isLoading,
                onToggle: _toggleTodo,
                onDelete: _deleteTodo,
                onEdit: _editTodo,
                onRefreshTags: _loadTags,
                onAIAction: _showAIInputDialog,
              )
            : _selectedIndex == 1
            ? TimelineScreen(key: const ValueKey('timeline'), todos: todos)
            : DashboardScreen(key: const ValueKey('dashboard'), todos: todos),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.task_alt_outlined),
            selectedIcon: const Icon(Icons.task_alt),
            label: l10n.tasks,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_today_outlined),
            selectedIcon: const Icon(Icons.calendar_today),
            label: l10n.timeline,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.dashboard,
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _showAddTodoDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
