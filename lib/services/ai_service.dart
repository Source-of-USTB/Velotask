import 'dart:async';
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
  final http.Client _httpClient;

  AIService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  Future<double?> estimateEffortHours({
    required String title,
    required String description,
    required int importance,
    DateTime? startDate,
    DateTime? ddl,
  }) async {
    final config = await _loadConfig();
    if (config == null) {
      _logger.fine('Skip effort estimation because AI config is missing');
      return null;
    }

    final now = DateTime.now();
    final prompt =
        '''
You are a task effort estimation engine.

Estimate effort hours (E) for the task. Output ONLY JSON:
{"estimatedHours": number}

Rules:
1) Return a single positive number in hours.
2) Consider title, description, priority, start/deadline if available.
3) Keep estimate practical for personal task management.
4) Use range [0.25, 100].
5) No markdown, no extra text.

Context:
- Current time: ${now.toIso8601String()}
- Title: "$title"
- Description: "$description"
- Importance: $importance (0 low, 1 normal, 2 high)
- Start: ${startDate?.toIso8601String() ?? 'null'}
- Deadline: ${ddl?.toIso8601String() ?? 'null'}
''';

    try {
      final response = await _httpClient
          .post(
            Uri.parse('${config.baseUrl}/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${config.apiKey}',
            },
            body: jsonEncode({
              'model': config.model,
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
              'temperature': 0.2,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        _logger.warning(
          'Effort estimation API error: ${response.statusCode} - ${response.body}',
        );
        return null;
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final content = data['choices'][0]['message']['content'].trim();
      final cleanContent = _stripMarkdownCodeBlock(content);
      final Map<String, dynamic> effortJson = jsonDecode(cleanContent);

      final raw = effortJson['estimatedHours'];
      final value = raw is num ? raw.toDouble() : double.tryParse('$raw');
      if (value == null || value <= 0) {
        return null;
      }
      return value.clamp(0.25, 100.0);
    } catch (e, stack) {
      _logger.warning('Effort estimation failed: $e');
      _logger.fine('Effort estimation stack: $stack');
      return null;
    }
  }

  Future<AIParseResult?> parseTask(
    String input, {
    List<String> existingTags = const [],
  }) async {
    final config = await _loadConfig();
    if (config == null) {
      _logger.warning('AI API configuration is missing');
      throw Exception('AI configuration missing');
    }

    final now = DateTime.now();
    final tagsContext = existingTags.isEmpty ? 'None' : existingTags.join(', ');

    final prompt =
        '''
You are an expert task parsing engine. Convert the user's natural language into ONE valid JSON object for a todo app.

[Context]
Current Time: ${now.toIso8601String()}
Today is: ${['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][now.weekday - 1]}
Existing tags: $tagsContext

[Output Schema - MUST follow exactly]
{
  "title": "Short task title",
  "description": "Optional concise description",
  "importance": 0,
  "startDate": "ISO8601 string or null",
  "deadline": "ISO8601 string or null",
  "tags": ["tag1", "tag2"]
}

[Hard Constraints]
1) Output ONLY raw JSON. No markdown, no code fence, no explanation.
2) "importance" must be integer: 0 (Low), 1 (Normal), 2 (High).
3) "startDate" and "deadline" must be ISO8601 or null.
4) "tags" must be an array of short strings, max 4 items.
5) Prefer the user's language style for title/description.

[Time Parsing Rules]
1) Resolve relative time from Current Time (today/tomorrow/next week/this weekend/in 2 hours, etc.).
2) If only one time point is mentioned, treat it as "deadline".
3) If a date is mentioned without time for deadline, default to 23:59 local time.
4) If time is mentioned without date, use the nearest future time.
5) If both start and end are implied (e.g., "8:30-10:30"), map start to "startDate" and end to "deadline".
6) If no reliable time is found, keep missing fields as null.

[Importance Heuristic]
- 2 (High): explicit urgency/critical words, exam/interview/deadline soon, overdue, strong consequence.
- 1 (Normal): ordinary actionable tasks with moderate urgency.
- 0 (Low): optional, someday, low-pressure, no urgency.

[Tag Rules]
1) Reuse Existing tags when semantically close (case-insensitive match).
2) Create new tags only when needed.
3) Use compact noun-like tags (e.g., "study", "work", "health").

[Quality Rules]
1) "title" should be short and actionable.
2) "description" should be concise, useful, and non-redundant.
3) Do not invent highly specific facts not implied by input.

User input: "$input"
''';

    try {
      _logger.info('AI parsing task: $input');

      final response = await _httpClient
          .post(
            Uri.parse('${config.baseUrl}/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${config.apiKey}',
            },
            body: jsonEncode({
              'model': config.model,
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
              'temperature': 0.1,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'].trim();

        final cleanContent = _stripMarkdownCodeBlock(content);

        final Map<String, dynamic> taskJson = jsonDecode(cleanContent);
        _logger.info('AI parse success: ${taskJson['title']}');
        return AIParseResult.fromJson(taskJson);
      } else {
        _logger.severe(
          'AI API error: ${response.statusCode} - ${response.body}',
        );
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e, stack) {
      _logger.severe('Failed to parse task via AI', e, stack);
      rethrow;
    }
  }

  Future<_AIConfig?> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('ai_base_url') ?? '';
    final apiKey = prefs.getString('ai_api_key') ?? '';
    final model = prefs.getString('ai_model') ?? 'gpt-3.5-turbo';

    if (baseUrl.isEmpty || apiKey.isEmpty) {
      return null;
    }

    final normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    return _AIConfig(baseUrl: normalizedBaseUrl, apiKey: apiKey, model: model);
  }

  String _stripMarkdownCodeBlock(String content) {
    final trimmed = content.trim();
    final codeBlockRegex = RegExp(
      r'^```[a-zA-Z0-9_-]*\s*([\s\S]*?)```$',
      caseSensitive: false,
    );
    final match = codeBlockRegex.firstMatch(trimmed);
    if (match != null) {
      return (match.group(1) ?? '').trim();
    }
    return content;
  }
}

class _AIConfig {
  final String baseUrl;
  final String apiKey;
  final String model;

  const _AIConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
  });
}
