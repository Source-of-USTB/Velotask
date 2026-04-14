import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:velotask/models/tag.dart';
import 'package:velotask/services/todo_storage.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('duplicate tag updates color without crash', (tester) async {
    final storage = TodoStorage();
    final key = DateTime.now().microsecondsSinceEpoch;
    final baseName = 'Work$key';

    final tag1 = Tag.unsaved(name: baseName, color: '#FF0000');
    final tag2 = Tag.unsaved(name: baseName, color: '#00FF00');

    await storage.addTag(tag1);
    await storage.addTag(tag2);

    final tags = await storage.loadTags();
    final matches = tags.where((t) => t.name == baseName).toList();

    expect(matches.length, 1);
    expect(matches.first.color, '#00FF00');
  });

  testWidgets('tag dedup is case-insensitive and trimmed', (tester) async {
    final storage = TodoStorage();
    final key = DateTime.now().microsecondsSinceEpoch;
    final baseName = 'Study$key';

    await storage.addTag(Tag.unsaved(name: '  $baseName  ', color: '#111111'));
    await storage.addTag(
      Tag.unsaved(name: baseName.toLowerCase(), color: '#222222'),
    );

    final tags = await storage.loadTags();
    final matches = tags
        .where((t) => t.name.trim().toLowerCase() == baseName.toLowerCase())
        .toList();

    expect(matches.length, 1);
    expect(matches.first.color, '#222222');
  });
}
