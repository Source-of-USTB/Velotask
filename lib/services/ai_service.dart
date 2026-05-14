import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velotask/utils/logger.dart';

typedef _JsonMap = Map<String, dynamic>;


// TODO: 升级后解析速度明显变慢了，考虑对解析速度进行量化并尽可能地优化。
// TODO: 尽可能让AI充分的利用已有信息，减少它的“想象力”，比如提供当前时间、星期、已有标签等上下文，让它更倾向于复用已有标签而不是创造新标签。
class AIParseResult {
  final String title;
  final String description;
  final int importance;
  final DateTime? startDate;
  final DateTime? ddl;
  final List<String> tags;
  final double? estimatedEffortHours;

  AIParseResult({
    required this.title,
    this.description = '',
    this.importance = 1,
    this.startDate,
    this.ddl,
    this.tags = const [],
    this.estimatedEffortHours,
  });

  factory AIParseResult.fromJson(Map<String, dynamic> json) {
    final rawImportance = json['importance'];
    final parsedImportance = rawImportance is int
        ? rawImportance
        : int.tryParse('${rawImportance ?? ''}');

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String) return DateTime.tryParse(value);
      return DateTime.tryParse('$value');
    }

    return AIParseResult(
      title: '${json['title'] ?? ''}'.trim(),
      description: '${json['description'] ?? ''}'.trim(),
      importance: (parsedImportance ?? 1).clamp(0, 2),
      startDate: parseDate(json['startDate']),
      ddl: parseDate(json['deadline']),
      tags: json['tags'] is List
          ? (json['tags'] as List)
              .map((e) => '$e'.trim())
              .where((e) => e.isNotEmpty)
              .take(4)
              .toList(growable: false)
          : const [],
      estimatedEffortHours: (json['estimatedHours'] is num)
          ? (json['estimatedHours'] as num).toDouble().clamp(0.25, 100.0)
          : double.tryParse(
              '${json['estimatedHours'] ?? ''}',
            )?.clamp(0.25, 100.0),
    );
  }
}

class AIService {
  static final Logger _logger = AppLogger.getLogger('AIService');
  final http.Client _httpClient;

  AIService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  void dispose() => _httpClient.close();

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
    final messages = [
      {
        'role': 'system',
        'content':
            'Estimate task effort hours for a personal todo app. Output ONLY JSON: {"estimatedHours":number}. Range: 0.25-100.',
      },
      {
        'role': 'user',
        'content': jsonEncode({
          'now': now.toIso8601String(),
          'title': title,
          'description': description,
          'importance': importance.clamp(0, 2),
          'startDate': startDate?.toIso8601String(),
          'deadline': ddl?.toIso8601String(),
        }),
      },
    ];

    try {
      final data = await _chatCompletionsJson(
        config,
        messages: messages,
        temperature: 0.1,
        maxTokens: 80,
        timeout: const Duration(seconds: 18),
        retries: 2,
        preferJsonMode: true,
      );

      final content = _extractAssistantContent(data);
      if (content == null) {
        return null;
      }
      final effortJson = _decodeJsonObject(_extractJsonPayload(content));

      final raw = effortJson['estimatedHours'];
      final value = raw is num ? raw.toDouble() : double.tryParse('$raw');
      if (value == null || value <= 0) {
        return null;
      }
      return value.clamp(0.25, 100.0);
    } catch (e, stack) {
      _logger.warning('Effort estimation failed', e, stack);
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
    final trimmedExistingTags = existingTags
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .take(30)
        .toList(growable: false);

    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowStr =
        '${tomorrow.toIso8601String().split('T').first}T15:00:00';

    final messages = [
      {
        'role': 'system',
        'content': [
          'Convert user input into ONE JSON task object. Output the JSON directly — NO reasoning, NO markdown fences, NO backticks, NO explanation.',
          '',
          'Keys:',
          '  title: concise task name, 2-15 words',
          '  description: details or empty string ""',
          '  importance: 0=low, 1=normal, 2=urgent (default 1)',
          '  startDate: ISO8601 string or null',
          '  deadline: ISO8601 string or null',
          '  tags: string array, max 4, reuse existingTags if semantically close',
          '  estimatedHours: number 0.25-100',
          '',
          'Date rules (reference "now" and "weekday" from user input):',
          '- "today" = now\'s date. "tomorrow" = now + 1 day. "next Monday" = the upcoming Monday.',
          '- Date-only deadline → append T23:59:00. Time-only → nearest future occurrence.',
          '- Single date/time mentioned → put it in deadline, leave startDate as null.',
          '- Two dates/times → earlier is startDate, later is deadline.',
          '- Format: "2026-04-30T15:00:00" (seconds always :00).',
          '',
          'Tags: pick exact match from existingTags when possible. Otherwise 1-2 word noun labels.',
          '',
          'Example — Input: "明天下午3点前交报告"',
          'Output: {"title":"交报告","description":"","importance":1,"startDate":null,"deadline":"$tomorrowStr","tags":["报告"],"estimatedHours":2}',
        ].join('\n'),
      },
      {
        'role': 'user',
        'content': jsonEncode({
          'now': now.toIso8601String(),
          'weekday': [
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday',
          ][now.weekday - 1],
          'existingTags': trimmedExistingTags,
          'input': input,
        }),
      },
    ];

    try {
      _logger.info('AI parsing task: $input');

      final data = await _chatCompletionsJson(
        config,
        messages: messages,
        temperature: 0.1,
        maxTokens: 2048,
        timeout: const Duration(seconds: 30),
        retries: 2,
        preferJsonMode: false,
      );

      final content = _extractAssistantContent(data);
      if (content == null) {
        throw const FormatException('AI returned empty response — see severe log for raw API response');
      }
      final taskJson = _decodeJsonObject(_extractJsonPayload(content));

      _logger.info('AI parse success: ${taskJson['title']}');
      return AIParseResult.fromJson(taskJson);
    } catch (e, stack) {
      _logger.severe('Failed to parse task via AI', e, stack);
      rethrow;
    }
  }

  Future<List<AIParseResult>> parseTasks(
    String input, {
    List<String> existingTags = const [],
  }) async {
    final config = await _loadConfig();
    if (config == null) {
      _logger.warning('AI API configuration is missing');
      throw Exception('AI configuration missing');
    }

    final now = DateTime.now();
    final trimmedExistingTags = existingTags
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .take(30)
        .toList(growable: false);

    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowStr =
        '${tomorrow.toIso8601String().split('T').first}T15:00:00';
    final daysUntilFri = (DateTime.friday - now.weekday + 7) % 7;
    final friday = now.add(Duration(days: daysUntilFri == 0 ? 7 : daysUntilFri));
    final fridayStr =
        '${friday.toIso8601String().split('T').first}T23:59:00';

    final messages = [
      {
        'role': 'system',
        'content': [
          'Convert user input into a JSON array of task objects. Output the JSON array directly — NO reasoning, NO markdown fences, NO backticks, NO explanation.',
          'If input contains multiple tasks (separated by semicolons, newlines, or numbered items), split accordingly.',
          '',
          'Each task keys:',
          '  title: concise task name, 2-15 words',
          '  description: details or empty string ""',
          '  importance: 0=low, 1=normal, 2=urgent (default 1)',
          '  startDate: ISO8601 string or null',
          '  deadline: ISO8601 string or null',
          '  tags: string array, max 4, reuse existingTags if semantically close',
          '  estimatedHours: number 0.25-100',
          '',
          'Date rules (reference "now" and "weekday" from user input):',
          '- "today" = now\'s date. "tomorrow" = now + 1 day. "next Monday" = the upcoming Monday.',
          '- Date-only deadline → append T23:59:00. Time-only → nearest future occurrence.',
          '- Single date/time mentioned → put it in deadline, leave startDate as null.',
          '- Two dates/times → earlier is startDate, later is deadline.',
          '- Format: "2026-04-30T15:00:00" (seconds always :00).',
          '',
          'Tags: pick exact match from existingTags when possible. Otherwise 1-2 word noun labels.',
          '',
          'Example — Input: "明天下午3点交报告; 周五前买书"',
          'Output: [{"title":"交报告","description":"","importance":1,"startDate":null,"deadline":"$tomorrowStr","tags":["报告"],"estimatedHours":2},{"title":"买书","description":"","importance":1,"startDate":null,"deadline":"$fridayStr","tags":["购物"],"estimatedHours":0.5}]',
        ].join('\n'),
      },
      {
        'role': 'user',
        'content': jsonEncode({
          'now': now.toIso8601String(),
          'weekday': [
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday',
          ][now.weekday - 1],
          'existingTags': trimmedExistingTags,
          'input': input,
        }),
      },
    ];

    try {
      _logger.info('AI parsing multiple tasks');

      final data = await _chatCompletionsJson(
        config,
        messages: messages,
        temperature: 0.1,
        maxTokens: 4096,
        timeout: const Duration(seconds: 35),
        retries: 2,
        preferJsonMode: false,
      );

      final content = _extractAssistantContent(data);
      if (content == null) {
        throw const FormatException('Missing assistant content — see severe log for raw API response');
      }
      final payload = _extractJsonPayload(content);
      final decoded = jsonDecode(payload);

      List<dynamic> rawTasks;
      if (decoded is List) {
        rawTasks = decoded;
      } else if (decoded is Map && decoded['tasks'] is List) {
        rawTasks = decoded['tasks'] as List;
      } else if (decoded is Map) {
        rawTasks = [decoded];
      } else {
        throw const FormatException('Decoded payload must be a JSON list');
      }

      final results = rawTasks
          .whereType<Map<String, dynamic>>()
          .map(AIParseResult.fromJson)
          .where((r) => r.title.trim().isNotEmpty)
          .toList(growable: false);

      if (results.isEmpty) {
        throw const FormatException('No tasks parsed');
      }

      _logger.info('AI parse success: ${results.length} tasks');
      return results;
    } catch (e, stack) {
      _logger.severe('Failed to parse tasks via AI', e, stack);
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

  Future<_JsonMap> _chatCompletionsJson(
    _AIConfig config, {
    required List<_JsonMap> messages,
    required double temperature,
    required int maxTokens,
    required Duration timeout,
    required int retries,
    required bool preferJsonMode,
  }) async {
    final uri = Uri.parse('${config.baseUrl}/chat/completions');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${config.apiKey}',
    };

    _JsonMap buildBody({required bool jsonMode}) {
      final body = <String, dynamic>{
        'model': config.model,
        'messages': messages,
        'temperature': temperature,
        'max_tokens': maxTokens,
        'n': 1,
        'stream': false,
      };
      if (jsonMode) {
        body['response_format'] = {'type': 'json_object'};
      }
      return body;
    }

    _logRequest(messages, config.model, maxTokens, preferJsonMode);

    Future<http.Response> doPost(_JsonMap body) => _postWithRetry(
          uri,
          headers: headers,
          body: jsonEncode(body),
          timeout: timeout,
          retries: retries,
        );

    final preferredBody = buildBody(jsonMode: preferJsonMode);
    final response = await doPost(preferredBody);

    _logResponse(response);

    if (response.statusCode == 400 && preferJsonMode) {
      final bodyText = utf8.decode(response.bodyBytes);
      final unsupportedResponseFormat = bodyText.contains('response_format') &&
          (bodyText.contains('unknown') ||
              bodyText.contains('Unrecognized') ||
              bodyText.contains('unsupported'));
      if (unsupportedResponseFormat) {
        _logger.info('json_mode not supported by provider, retrying without');
        final fallbackResponse = await doPost(buildBody(jsonMode: false));
        _logResponse(fallbackResponse);
        return _decodeTopLevelJson(fallbackResponse);
      }
    }

    return _decodeTopLevelJson(response);
  }

  void _logRequest(List<_JsonMap> messages, String model, int maxTokens, bool jsonMode) {
    Map<String, dynamic> userMsg = messages.last;
    for (final m in messages) {
      if (m['role'] == 'user') userMsg = m;
    }
    final content = userMsg['content'] is String
        ? userMsg['content'] as String
        : jsonEncode(userMsg['content']);
    _logger.info('AI request → model=$model, maxTokens=$maxTokens, jsonMode=$jsonMode, userInput: ${content.length > 300 ? '${content.substring(0, 300)}...' : content}');
  }

  void _logResponse(http.Response response) {
    final bodyText = utf8.decode(response.bodyBytes);
    final truncated = bodyText.length > 600 ? '${bodyText.substring(0, 600)}...' : bodyText;
    _logger.info('AI response ← status=${response.statusCode}, body=$truncated');
  }

  Future<http.Response> _postWithRetry(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
    required Duration timeout,
    required int retries,
  }) async {
    Object? lastError;
    StackTrace? lastStack;
    http.Response? lastResponse;

    for (var attempt = 0; attempt <= retries; attempt++) {
      if (attempt > 0) {
        final retryAfter = _parseRetryAfterSeconds(lastResponse?.headers);
        final backoffMs = retryAfter != null
            ? (retryAfter * 1000)
            : (300 * (1 << (attempt - 1)));
        await Future.delayed(Duration(milliseconds: backoffMs.clamp(200, 2500)));
      }

      try {
        final response = await _httpClient
            .post(uri, headers: headers, body: body)
            .timeout(timeout);
        lastResponse = response;

        if (response.statusCode == 200) {
          return response;
        }

        if (attempt >= retries) {
          return response;
        }

        if (!_shouldRetryStatus(response.statusCode)) {
          return response;
        }
      } catch (e, stack) {
        lastError = e;
        lastStack = stack;
        if (attempt >= retries) {
          Error.throwWithStackTrace(lastError, lastStack);
        }
      }
    }

    if (lastResponse != null) {
      return lastResponse;
    }
    Error.throwWithStackTrace(
      lastError ?? TimeoutException('Unknown network failure'),
      lastStack ?? StackTrace.current,
    );
  }

  bool _shouldRetryStatus(int statusCode) {
    return statusCode == 408 ||
        statusCode == 429 ||
        statusCode == 500 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504;
  }

  int? _parseRetryAfterSeconds(Map<String, String>? headers) {
    final value = headers?['retry-after'];
    if (value == null) return null;
    return int.tryParse(value);
  }

  _JsonMap _decodeTopLevelJson(http.Response response) {
    final bodyText = utf8.decode(response.bodyBytes);
    if (response.statusCode != 200) {
      throw Exception('API Error: ${response.statusCode} — ${bodyText.length > 500 ? '${bodyText.substring(0, 500)}...' : bodyText}');
    }

    final decoded = jsonDecode(bodyText);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Top-level response must be a JSON object: ${bodyText.length > 300 ? '${bodyText.substring(0, 300)}...' : bodyText}');
    }
    return decoded;
  }

  String? _extractAssistantContent(_JsonMap data) {
    final choices = data['choices'];
    if (choices is! List || choices.isEmpty) {
      _logger.severe('AI response has no choices array. Keys: ${data.keys.join(', ')}');
      return null;
    }
    final choice0 = choices.first;
    if (choice0 is! Map) {
      _logger.severe('AI choice[0] is not a map: $choice0');
      return null;
    }
    final message = choice0['message'];
    if (message is! Map) {
      _logger.severe('AI choice[0] has no "message" key. Keys: ${choice0.keys.join(', ')}');
      return null;
    }
    dynamic content = message['content'];
    var source = 'content';
    if ((content == null || (content is String && content.trim().isEmpty)) &&
        message['reasoning_content'] is String &&
        (message['reasoning_content'] as String).trim().isNotEmpty) {
      content = message['reasoning_content'];
      source = 'reasoning_content';
    }
    if (content is! String || content.trim().isEmpty) {
      _logger.severe('AI message has no usable content. message keys: ${message.keys.join(', ')}. content type: ${content.runtimeType}, content: ${content is String ? (content.length > 100 ? '${content.substring(0, 100)}...' : content) : content}');
      return null;
    }
    _logger.info('AI extract source=$source, contentLen=${content.length}');
    return content.trim();
  }

  _JsonMap _decodeJsonObject(String payload) {
    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Decoded payload must be a JSON object');
    }
    return decoded;
  }

  String _extractJsonPayload(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('AI returned empty response');
    }

    final fenced = RegExp(
      r'```[a-zA-Z0-9_-]*\s*([\s\S]*?)```',
      caseSensitive: false,
    );
    for (final match in fenced.allMatches(trimmed)) {
      final candidate = (match.group(1) ?? '').trim();
      final extracted = _scanFirstJsonValue(candidate);
      if (extracted != null) {
        return extracted;
      }
    }

    final extracted = _scanFirstJsonValue(trimmed);
    if (extracted != null) {
      return extracted;
    }

    throw FormatException('AI response is not valid JSON: ${trimmed.length > 200 ? '${trimmed.substring(0, 200)}...' : trimmed}');
  }

  String? _scanFirstJsonValue(String input) {
    final objectIndex = input.indexOf('{');
    final arrayIndex = input.indexOf('[');

    if (objectIndex < 0 && arrayIndex < 0) {
      return null;
    }
    if (arrayIndex >= 0 && (objectIndex < 0 || arrayIndex < objectIndex)) {
      return _scanFirstJsonArray(input);
    }
    return _scanFirstJsonObject(input);
  }

  String? _scanFirstJsonObject(String input) {
    final start = input.indexOf('{');
    if (start < 0) return null;

    var depth = 0;
    var inString = false;
    var escape = false;

    for (var i = start; i < input.length; i++) {
      final char = input.codeUnitAt(i);

      if (inString) {
        if (escape) {
          escape = false;
          continue;
        }
        if (char == 0x5C) {
          escape = true;
          continue;
        }
        if (char == 0x22) {
          inString = false;
        }
        continue;
      }

      if (char == 0x22) {
        inString = true;
        continue;
      }

      if (char == 0x7B) {
        depth++;
      } else if (char == 0x7D) {
        depth--;
        if (depth == 0) {
          return input.substring(start, i + 1).trim();
        }
      }
    }

    return null;
  }

  String? _scanFirstJsonArray(String input) {
    final start = input.indexOf('[');
    if (start < 0) return null;

    var depth = 0;
    var inString = false;
    var escape = false;

    for (var i = start; i < input.length; i++) {
      final char = input.codeUnitAt(i);

      if (inString) {
        if (escape) {
          escape = false;
          continue;
        }
        if (char == 0x5C) {
          escape = true;
          continue;
        }
        if (char == 0x22) {
          inString = false;
        }
        continue;
      }

      if (char == 0x22) {
        inString = true;
        continue;
      }

      if (char == 0x5B) {
        depth++;
      } else if (char == 0x5D) {
        depth--;
        if (depth == 0) {
          return input.substring(start, i + 1).trim();
        }
      }
    }

    return null;
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
