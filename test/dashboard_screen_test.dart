import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velotask/l10n/app_localizations.dart';
import 'package:velotask/models/todo.dart';
import 'package:velotask/screens/dashboard_screen.dart';

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
  testWidgets('Dashboard shows profile and task stats', (
    WidgetTester tester,
  ) async {
    final todos = [
      Todo(
        title: 'A',
        isCompleted: false,
        importance: 2,
        ddl: DateTime.now().add(const Duration(hours: 1)),
      ),
      Todo(title: 'B', isCompleted: true, importance: 1),
      Todo(
        title: 'C',
        isCompleted: false,
        importance: 0,
        ddl: DateTime.now().add(const Duration(days: 30)),
      ),
    ];

    await tester.pumpWidget(
      createLocalizedWidgetForTesting(child: DashboardScreen(todos: todos)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Task Stats'), findsOneWidget);
    expect(find.text('Completed Tasks'), findsOneWidget);
    expect(find.text('High Urgency'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('1'), findsAtLeastNWidgets(2));
  });
}
