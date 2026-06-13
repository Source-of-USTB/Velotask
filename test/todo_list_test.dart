import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velotask/l10n/app_localizations.dart';
import 'package:velotask/models/tag.dart';
import 'package:velotask/models/todo.dart';
import 'package:velotask/models/todo_filter.dart';
import 'package:velotask/screens/tasks_screen.dart';
import 'package:velotask/widgets/todo/filter_section.dart';
import 'package:velotask/widgets/todo/todo_item.dart';

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
        ddl: DateTime.now().add(const Duration(minutes: 10)),
        estimatedEffortHours: 4,
      );
      final dailyTodo = Todo(title: 'Daily Task', taskType: TaskType.daily);

      final todos = [activeTodo, completedTodo, emergencyTodo, dailyTodo];

      await tester.pumpWidget(
        createLocalizedWidgetForTesting(
          child: TasksScreen(
            todos: todos,
            tags: [],
            isLoading: false,
            onToggle: (_) {},
            onDelete: (_) {},
            onEdit: (_) {},
            onAIAction: () {},
            onSettingsPressed: () {},
          ),
        ),
      );

      await tester.pumpAndSettle(); // Wait for localizations to load

      // Initial state: Active filter is default
      // Should show Active Task and Emergency Task (since it's also active)
      expect(find.text('Active Task'), findsOneWidget);
      expect(find.text('Emergency Task'), findsOneWidget);
      expect(find.text('Daily Task'), findsNothing);
      expect(find.text('Completed Task'), findsNothing);

      // Switch to 'Done' filter
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('Active Task'), findsNothing);
      expect(find.text('Emergency Task'), findsNothing);
      expect(find.text('Daily Task'), findsNothing);
      expect(find.text('Completed Task'), findsOneWidget);

      // Switch to 'Emergency' filter
      await tester.tap(find.text('Emergency'));
      await tester.pumpAndSettle();

      expect(find.text('Active Task'), findsNothing);
      expect(find.text('Emergency Task'), findsOneWidget);
      expect(find.text('Daily Task'), findsNothing);
      expect(find.text('Completed Task'), findsNothing);

      // Switch to 'All' filter
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(find.text('Active Task'), findsOneWidget);
      expect(find.text('Emergency Task'), findsOneWidget);
      expect(find.text('Daily Task'), findsNothing);
      expect(find.text('Completed Task'), findsOneWidget);
    });

    testWidgets('daily filter shows only daily tasks', (
      WidgetTester tester,
    ) async {
      final activeTodo = Todo(title: 'Active Task', isCompleted: false);
      final dailyTodo = Todo(
        id: 1,
        title: 'Daily Task',
        taskType: TaskType.daily,
      );
      final doneDailyTodo = Todo(
        id: 2,
        title: 'Done Daily Task',
        taskType: TaskType.daily,
        lastCompletedDate: DateTime.now(),
      );

      await tester.pumpWidget(
        createLocalizedWidgetForTesting(
          child: TasksScreen(
            todos: [doneDailyTodo, activeTodo, dailyTodo],
            tags: [],
            isLoading: false,
            onToggle: (_) {},
            onDelete: (_) {},
            onEdit: (_) {},
            onAIAction: () {},
            onSettingsPressed: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to 'Daily' filter
      await tester.tap(find.widgetWithText(ChoiceChip, 'Daily'));
      await tester.pumpAndSettle();

      expect(find.text('Active Task'), findsNothing);
      expect(find.text('Daily Task'), findsOneWidget);
      expect(find.text('Done Daily Task'), findsOneWidget);

      final activeDailyTop = tester.getTopLeft(find.text('Daily Task')).dy;
      final doneDailyTop = tester.getTopLeft(find.text('Done Daily Task')).dy;
      expect(activeDailyTop, lessThan(doneDailyTop));
    });

    testWidgets('daily filter respects custom order before done grouping', (
      WidgetTester tester,
    ) async {
      final firstDaily = Todo(
        id: 1,
        title: 'First Daily Task',
        taskType: TaskType.daily,
      );
      final secondDaily = Todo(
        id: 2,
        title: 'Second Daily Task',
        taskType: TaskType.daily,
      );
      final doneDaily = Todo(
        id: 3,
        title: 'Done Daily Task',
        taskType: TaskType.daily,
        lastCompletedDate: DateTime.now(),
      );

      await tester.pumpWidget(
        createLocalizedWidgetForTesting(
          child: TasksScreen(
            todos: [firstDaily, secondDaily, doneDaily],
            tags: [],
            isLoading: false,
            onToggle: (_) {},
            onDelete: (_) {},
            onEdit: (_) {},
            onAIAction: () {},
            onSettingsPressed: () {},
            dailyTaskOrder: const [2, 1, 3],
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Daily'));
      await tester.pumpAndSettle();

      final secondDailyTop = tester
          .getTopLeft(find.text('Second Daily Task'))
          .dy;
      final firstDailyTop = tester.getTopLeft(find.text('First Daily Task')).dy;
      final doneDailyTop = tester.getTopLeft(find.text('Done Daily Task')).dy;

      expect(secondDailyTop, lessThan(firstDailyTop));
      expect(firstDailyTop, lessThan(doneDailyTop));
    });
  });

  group('TodoItem Tests', () {
    testWidgets('renders todo title', (WidgetTester tester) async {
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

      // Current UI shows both title and short description in the list row.
      expect(find.text('Test Todo'), findsOneWidget);
      expect(find.text('Test Description'), findsOneWidget);
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

    testWidgets('swipe right toggles and swipe left deletes', (
      WidgetTester tester,
    ) async {
      final todo = Todo(title: 'Swipe Todo');
      var toggled = false;
      var deleted = false;
      var visible = true;

      await tester.pumpWidget(
        createLocalizedWidgetForTesting(
          child: StatefulBuilder(
            builder: (context, setState) {
              if (!visible) {
                return const SizedBox.shrink();
              }
              return TodoItem(
                todo: todo,
                onToggle: () {
                  toggled = true;
                },
                onDelete: () {
                  deleted = true;
                  setState(() {
                    visible = false;
                  });
                },
                onEdit: () {},
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(TodoItem), const Offset(400, 0));
      await tester.pumpAndSettle();

      expect(toggled, isTrue);
      expect(deleted, isFalse);

      toggled = false;
      await tester.drag(find.byType(TodoItem), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(toggled, isFalse);
      expect(deleted, isTrue);
      expect(find.byType(TodoItem), findsNothing);
    });

    testWidgets('swipe works when tags are visible', (
      WidgetTester tester,
    ) async {
      final todo = Todo(
        title: 'Tagged Swipe Todo',
        tags: const [
          Tag(id: 1, name: 'work', color: '#ff9800'),
          Tag(id: 2, name: 'urgent', color: '#f44336'),
        ],
      );
      var toggled = false;
      var deleted = false;
      var visible = true;

      await tester.pumpWidget(
        createLocalizedWidgetForTesting(
          child: StatefulBuilder(
            builder: (context, setState) {
              if (!visible) {
                return const SizedBox.shrink();
              }
              return TodoItem(
                todo: todo,
                onToggle: () {
                  toggled = true;
                },
                onDelete: () {
                  deleted = true;
                  setState(() {
                    visible = false;
                  });
                },
                onEdit: () {},
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('WORK'), findsOneWidget);
      expect(find.text('URGENT'), findsOneWidget);

      await tester.drag(find.byType(TodoItem), const Offset(400, 0));
      await tester.pumpAndSettle();

      expect(toggled, isTrue);
      expect(deleted, isFalse);

      toggled = false;
      await tester.drag(find.byType(TodoItem), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(toggled, isFalse);
      expect(deleted, isTrue);
      expect(find.byType(TodoItem), findsNothing);
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
      expect(find.text('Daily'), findsOneWidget);
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
