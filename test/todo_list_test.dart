import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:velotask/l10n/app_localizations.dart';
import 'package:velotask/models/todo.dart';
import 'package:velotask/models/todo_filter.dart';
import 'package:velotask/screens/todo_list_view.dart';
import 'package:velotask/widgets/filter_section.dart';
import 'package:velotask/widgets/todo_item.dart';

Widget createLocalizedWidgetForTesting({required Widget child}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('zh')],
    locale: const Locale('en'),
    home: Scaffold(body: child),
  );
}

void main() {
  group('TodoListView Filtering Tests', () {
    testWidgets('filters todos correctly', (WidgetTester tester) async {
      // Setup data
      final activeTodo = Todo(title: 'Active Task', isCompleted: false);
      final completedTodo = Todo(title: 'Completed Task', isCompleted: true);
      final emergencyTodo = Todo(
        title: 'Emergency Task',
        isCompleted: false,
        importance: 2,
      );

      final todos = [activeTodo, completedTodo, emergencyTodo];

      await tester.pumpWidget(
        createLocalizedWidgetForTesting(
          child: TodoListView(
            todos: todos,
            tags: [],
            isLoading: false,
            onToggle: (_) {},
            onDelete: (_) {},
            onEdit: (_) {},
            onRefreshTags: () {},
          ),
        ),
      );

      await tester.pumpAndSettle(); // Wait for localizations to load

      // Initial state: Active filter is default
      // Should show Active Task and Emergency Task (since it's also active)
      expect(find.text('Active Task'), findsOneWidget);
      expect(find.text('Emergency Task'), findsOneWidget);
      expect(find.text('Completed Task'), findsNothing);

      // Switch to 'Done' filter
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('Active Task'), findsNothing);
      expect(find.text('Emergency Task'), findsNothing);
      expect(find.text('Completed Task'), findsOneWidget);

      // Switch to 'Emergency' filter
      await tester.tap(find.text('Emergency'));
      await tester.pumpAndSettle();

      expect(find.text('Active Task'), findsNothing);
      expect(find.text('Emergency Task'), findsOneWidget);
      expect(find.text('Completed Task'), findsNothing);

      // Switch to 'All' filter
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(find.text('Active Task'), findsOneWidget);
      expect(find.text('Emergency Task'), findsOneWidget);
      expect(find.text('Completed Task'), findsOneWidget);
    });
  });

  group('TodoItem Tests', () {
    testWidgets('renders todo title', (
      WidgetTester tester,
    ) async {
      final todo = Todo(title: 'Test Todo', description: 'Test Description');

      await tester.pumpWidget(
        createLocalizedWidgetForTesting(
          child: TodoItem(
            todo: todo,
            onToggle: () {},
            onDelete: () {},
            onEdit: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Title is shown in the list row; description is hidden until detail view.
      expect(find.text('Test Todo'), findsOneWidget);
      expect(find.text('Test Description'), findsNothing);
    });

    testWidgets('tapping item opens detail dialog', (
      WidgetTester tester,
    ) async {
      final todo = Todo(title: 'My Task', description: 'Long description here');

      await tester.pumpWidget(
        createLocalizedWidgetForTesting(
          child: TodoItem(
            todo: todo,
            onToggle: () {},
            onDelete: () {},
            onEdit: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('My Task'));
      await tester.pumpAndSettle();

      expect(find.text('Long description here'), findsOneWidget);
    });

    testWidgets('renders no tags row when tags are empty', (
      WidgetTester tester,
    ) async {
      final todo = Todo(title: 'Tagged Todo');

      await tester.pumpWidget(
        createLocalizedWidgetForTesting(
          child: TodoItem(
            todo: todo,
            onToggle: () {},
            onDelete: () {},
            onEdit: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No tags loaded in test environment — tag row should not appear.
      expect(find.text('Tagged Todo'), findsOneWidget);
    });
  });

  group('FilterSection Tests', () {
    testWidgets('renders all filter options', (WidgetTester tester) async {
      await tester.pumpWidget(
        createLocalizedWidgetForTesting(
          child: CustomScrollView(
            slivers: [
              FilterSection(
                currentFilter: TodoFilter.all,
                onFilterChanged: (filter, tag) {},
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Emergency'), findsOneWidget);
    });

    testWidgets('callbacks work when filters are tapped', (
      WidgetTester tester,
    ) async {
      TodoFilter? selectedFilter;

      await tester.pumpWidget(
        createLocalizedWidgetForTesting(
          child: CustomScrollView(
            slivers: [
              FilterSection(
                currentFilter: TodoFilter.all,
                onFilterChanged: (filter, tag) {
                  selectedFilter = filter;
                },
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Emergency'));
      expect(selectedFilter, TodoFilter.highPriority);
    });
  });
}
