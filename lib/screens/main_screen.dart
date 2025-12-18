import 'package:flutter/material.dart';
import 'package:velotask/models/tag.dart';
import 'package:velotask/models/todo.dart';
import 'package:velotask/screens/timeline_screen.dart';
import 'package:velotask/screens/todo_list_view.dart';
import 'package:velotask/services/todo_storage.dart';
import 'package:velotask/widgets/add_todo_dialog.dart';
import 'package:velotask/l10n/app_localizations.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadTodos(), _loadTags()]);
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTags() async {
    final loadedTags = await _storage.loadTags();
    if (mounted) {
      setState(() {
        tags = loadedTags;
      });
    }
  }

  Future<void> _loadTodos() async {
    final loadedTodos = await _storage.loadTodos();
    if (mounted) {
      setState(() {
        todos = loadedTodos;
      });
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
    if (mounted) {
      setState(() {
        final index = todos.indexWhere((t) => t.id == todo.id);
        if (index != -1) {
          todos[index] = updatedTodo;
        }
      });
    }
    await _storage.updateTodo(updatedTodo);
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
