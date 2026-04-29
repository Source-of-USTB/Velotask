import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velotask/l10n/app_localizations.dart';
import 'package:velotask/widgets/add_todo_dialog.dart';

void main() {
  testWidgets('AddTodoDialog date picker test', (WidgetTester tester) async {
    DateTime? selectedStartDate;
    DateTime? selectedDdl;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('zh')],
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AddTodoDialog(
                      onAdd: (title, desc, startDate, ddl, importance, tags, taskType) {
                        selectedStartDate = startDate;
                        selectedDdl = ddl;
                      },
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              );
            },
          ),
        ),
      ),
    );

    // Open the dialog
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Verify initial state: Start Date is now with includeTime, so it shows M/d HH:mm
    final now = DateTime.now();
    final expectedDateStr = '${now.month}/${now.day} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    expect(find.text(expectedDateStr), findsOneWidget);

    // Find the "To" date picker (DDL)
    // It has label 'To'
    final toPicker = find.ancestor(
      of: find.text('To'),
      matching: find.byType(InkWell),
    );

    // Tap "To" picker to open date picker
    await tester.tap(toPicker);
    await tester.pumpAndSettle();

    // Select today's date (always valid since "To" picker's firstDate is _startDate = now)
    final targetDay = now.day;
    await tester.tap(find.text('$targetDay'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Deadline now includes time selection; confirm default time.
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Fill in the title and save, then check the callback values.
    await tester.enterText(find.byType(TextField).first, 'Test Task');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    // Verify callback
    expect(selectedDdl, isNotNull);
    expect(selectedDdl!.day, targetDay);
    expect(selectedStartDate, isNotNull);
  });
}
