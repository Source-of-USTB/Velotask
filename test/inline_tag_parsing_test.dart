import 'package:flutter_test/flutter_test.dart';

/// Duplicates the inline tag regex and helper from AddTodoDialog
/// so tests stay in sync with the real implementation.
const _tagPattern = r'#([^\\]+)\\#';

(List<String>, String) extractInlineTags(String text) {
  final tagNames = <String>[];
  final cleaned = text.replaceAllMapped(RegExp(_tagPattern), (match) {
    final name = match.group(1)!.trim();
    if (name.isNotEmpty) {
      tagNames.add(name);
    }
    return '';
  });
  return (tagNames, cleaned.trim());
}

void main() {
  group('inline tag parsing — extraction', () {
    test('single tag', () {
      final (names, _) = extractInlineTags(r'#test\#');
      expect(names, ['test']);
    });

    test('multiple tags', () {
      final (names, _) = extractInlineTags(r'#tag1\# #tag2\#');
      expect(names, ['tag1', 'tag2']);
    });

    test('tag with surrounding text', () {
      final (names, _) = extractInlineTags(r'Buy groceries #shopping\# tomorrow');
      expect(names, ['shopping']);
    });

    test('tag with spaces in name', () {
      final (names, _) = extractInlineTags(r'#my important tag\#');
      expect(names, ['my important tag']);
    });

    test('tag with special characters', () {
      final (names, _) = extractInlineTags(r'#tag_123\#');
      expect(names, ['tag_123']);
    });

    test('tag with CJK characters', () {
      final (names, _) = extractInlineTags(r'#购物\#');
      expect(names, ['购物']);
    });

    test('two adjacent tags no space', () {
      final (names, _) = extractInlineTags(r'#a\##b\#');
      expect(names, ['a', 'b']);
    });

    test('preserves original case', () {
      final (names, _) = extractInlineTags(r'#Shopping\#');
      expect(names, ['Shopping']);
    });

    test('leading trailing whitespace in tag name is trimmed', () {
      final (names, _) = extractInlineTags(r'#  padded  \#');
      expect(names, ['padded']);
    });
  });

  group('inline tag parsing — non-matches', () {
    test('empty tag name is ignored', () {
      final (names, _) = extractInlineTags(r'#\#');
      expect(names, isEmpty);
    });

    test('whitespace-only tag name is ignored', () {
      final (names, _) = extractInlineTags(r'#  \#');
      expect(names, isEmpty);
    });

    test('no closing backslash (old format)', () {
      final (names, _) = extractInlineTags(r'#tag#');
      expect(names, isEmpty);
    });

    test('no opening hash', () {
      final (names, _) = extractInlineTags(r'tag\#');
      expect(names, isEmpty);
    });

    test('hash only without closing', () {
      final (names, _) = extractInlineTags(r'hello #world today');
      expect(names, isEmpty);
    });

    test('backslash-hash only without opening', () {
      final (names, _) = extractInlineTags(r'hello world\#');
      expect(names, isEmpty);
    });

    test('no tags in plain text', () {
      final (names, _) = extractInlineTags('Hello world, nothing here.');
      expect(names, isEmpty);
    });

    test('hash inside word without backslash', () {
      final (names, _) = extractInlineTags('#include something');
      expect(names, isEmpty);
    });

    test('backslash before hash in middle of text', () {
      final (names, _) = extractInlineTags(r'escape \# in text');
      expect(names, isEmpty);
    });
  });

  group('inline tag parsing — text cleaning', () {
    test('tag at start', () {
      final (_, cleaned) = extractInlineTags(r'#tag\# rest');
      expect(cleaned, 'rest');
    });

    test('tag at end', () {
      final (_, cleaned) = extractInlineTags(r'text #tag\#');
      expect(cleaned, 'text');
    });

    test('tag in middle', () {
      final (_, cleaned) = extractInlineTags(r'before #tag\# after');
      expect(cleaned, 'before  after');
    });

    test('multiple tags scattered', () {
      final (_, cleaned) = extractInlineTags(r'#a\# middle #b\#');
      expect(cleaned, 'middle');
    });

    test('only tags, no other text', () {
      final (_, cleaned) = extractInlineTags(r'#a\# #b\#');
      expect(cleaned, '');
    });

    test('text without tags passes through', () {
      final (_, cleaned) = extractInlineTags('Hello world');
      expect(cleaned, 'Hello world');
    });

    test('leading trailing whitespace is trimmed', () {
      final (_, cleaned) = extractInlineTags(r'  hello #tag\#  ');
      expect(cleaned, 'hello');
    });
  });

  group('inline tag parsing — dedup edge cases', () {
    test('same tag name twice yields two entries (caller deduplicates)', () {
      final (names, _) = extractInlineTags(r'#tag\# #tag\#');
      expect(names, ['tag', 'tag']);
    });

    test('case-different tags yield two entries (caller normalizes)', () {
      final (names, _) = extractInlineTags(r'#Tag\# #tag\#');
      expect(names, ['Tag', 'tag']);
    });

    test('empty input', () {
      final (names, cleaned) = extractInlineTags('');
      expect(names, isEmpty);
      expect(cleaned, '');
    });
  });
}
