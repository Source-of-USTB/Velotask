import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velotask/utils/logger.dart';

class AIParseResult {
  final String title;
  final String description;
  final int importance;
  final DateTime? startDate;
  final DateTime? ddl;
  final List<String> tags;

  AIParseResult({
    required this.title,
    this.description = '',
    this.importance = 1,
    this.startDate,
    this.ddl,
    this.tags = const [],
  });

  factory AIParseResult.fromJson(Map<String, dynamic> json) {
    return AIParseResult(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      importance: json['importance'] ?? 1,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'])
          : null,
      ddl: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'])
          : null,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : const [],
    );
  }
}

class AIService {
  static final Logger _logger = AppLogger.getLogger('AIService');

  Future<AIParseResult?> parseTask(
    String input, {
    List<String> existingTags = const [],
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('ai_base_url') ?? '';
    final apiKey = prefs.getString('ai_api_key') ?? '';
    final model = prefs.getString('ai_model') ?? 'gpt-3.5-turbo';

    if (baseUrl.isEmpty || apiKey.isEmpty) {
      _logger.warning('AI API configuration is missing');
      throw Exception('AI configuration missing');
    }

    final now = DateTime.now();
    final tagsContext = existingTags.isEmpty ? 'None' : existingTags.join(', ');

    final prompt =
        '''
You are a task management assistant. Parse the user's natural language input into a structured JSON object.

[Context]
Current Time: ${now.toIso8601String()}
Today is: ${['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][now.weekday - 1]}
Existing tags: $tagsContext

[Output Schema]
{
  "title": "Short task title",
  "description": "Optional description",
  "importance": 0 (Low), 1 (Normal), or 2 (High),
  "startDate": "ISO8601 string or null",
  "deadline": "ISO8601 string or null",
  "tags": ["tag1", "tag2"]
}

[Rules]
1. Resolve relative dates (e.g., "next Wednesday", "tomorrow", "this weekend") based on the Current Time provided.
2. If only one date/time is mentioned, it is usually the "deadline".
3. Extract or suggest relevant tags. PREFER reusing existing tags listed above. Create new tags only when necessary and avoid being overly aggressive.
4. Autonomously write a helpful and concise "description" based on the task context.
5. Return ONLY the JSON object, no other text.

User input: "$input"
''';

    try {
      _logger.info('AI parsing task: $input');

      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.1,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'].trim();

        // Remove markdown code blocks if present
        String cleanContent = content;
        if (content.startsWith('```json')) {
          cleanContent = content.substring(7, content.length - 3);
        } else if (content.startsWith('```')) {
          cleanContent = content.substring(3, content.length - 3);
        }

        final Map<String, dynamic> taskJson = jsonDecode(cleanContent);
        _logger.info('AI parse success: ${taskJson['title']}');
        return AIParseResult.fromJson(taskJson);
      } else {
        _logger.severe(
          'AI API error: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e, stack) {
      _logger.severe('Failed to parse task via AI', e, stack);
      return null;
    }
  }
}
