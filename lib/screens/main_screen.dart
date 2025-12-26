import 'package:flutter/material.dart';
import 'package:velotask/models/tag.dart';
import 'package:velotask/models/todo.dart';
import 'package:velotask/screens/timeline_screen.dart';
import 'package:velotask/screens/todo_list_view.dart';
import 'package:velotask/services/todo_storage.dart';
import 'package:velotask/services/ai_service.dart';
import 'package:velotask/widgets/add_todo_dialog.dart';
import 'package:velotask/widgets/ai_input_dialog.dart';
import 'package:velotask/l10n/app_localizations.dart';
import 'package:velotask/utils/logger.dart';

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
  static final Logger _logger = AppLogger.getLogger('MainScreen');

  @override
  void initState() {
    super.initState();
    _logger.info('MainScreen initialized');
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await Future.wait([_loadTodos(), _loadTags()]);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.severe('Failed to load data', e);
    }
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
    List<Tag> tags,
  ) async {
    if (title.isEmpty) return;

    final newTodo = Todo(
      title: title,
      description: desc,
      startDate: startDate,
      ddl: ddl,
      importance: importance,
    );
    newTodo.tags.addAll(tags);

    await _storage.addTodo(newTodo);
    if (mounted) {
      setState(() {
        todos.add(newTodo);
      });
    }
  }

  Future<void> _deleteTodo(Todo todo) async {
    await _storage.deleteTodo(todo.id);
    if (mounted) {
      setState(() {
        todos.removeWhere((t) => t.id == todo.id);
      });
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
  }

  Future<void> _editTodo(Todo todo) async {
    showDialog(
      context: context,
      builder: (context) => AddTodoDialog(
        todo: todo,
        onAdd: (title, desc, startDate, ddl, importance, tags) async {
          final updatedTodo = todo.copyWith(
            title: title,
            description: desc,
            startDate: startDate,
            ddl: ddl,
            importance: importance,
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
    final result = await showDialog<AIParseResult>(
      context: context,
      builder: (context) =>
          AIInputDialog(existingTags: tags.map((t) => t.name).toList()),
    );

    if (result != null && mounted) {
      // Map AI result to Todo fields
      final title = result.title;
      final desc = result.description;
      final importance = result.importance;
      final startDate = result.startDate;
      final ddl = result.ddl;

      // Handle tags
      List<Tag> selectedTags = [];
      bool tagsAdded = false;
      for (final name in result.tags) {
        // Find existing tag or create new one
        var tag = tags.cast<Tag?>().firstWhere(
          (t) => t?.name.toLowerCase() == name.toLowerCase(),
          orElse: () => null,
        );

        if (tag == null) {
          tag = Tag(name: name);
          await _storage.addTag(tag);
          tagsAdded = true;
        }
        selectedTags.add(tag);
      }

      if (tagsAdded) {
        await _loadTags(); // Refresh tags list once
        // Re-map selectedTags to the newly loaded tag objects to ensure they have IDs
        selectedTags = result.tags.map((name) {
          return tags.firstWhere((t) => t.name.toLowerCase() == name.toLowerCase());
        }).toList();
      }

      await _addTodo(title, desc, startDate, ddl, importance, selectedTags);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          TodoListView(
            todos: todos,
            tags: tags,
            isLoading: _isLoading,
            onToggle: _toggleTodo,
            onDelete: _deleteTodo,
            onEdit: _editTodo,
            onRefreshTags: _loadTags,
            onAIAction: _showAIInputDialog,
          ),
          TimelineScreen(todos: todos),
        ],
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
