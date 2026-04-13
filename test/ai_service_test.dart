import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velotask/services/ai_service.dart';

// TODO: 增加更多测试用例，覆盖边界情况和异常情况，比如AI返回非JSON格式、缺失字段、网络异常等。
// TODO: 实际测试中发现新版的AI解析算法速度明显变慢了，考虑对解析速度进行量化并尽可能地量化。
void main() {
  group('AIParseResult.fromJson', () {
    test('parses complete payload correctly', () {
      final result = AIParseResult.fromJson({
        'title': 'Final exam',
        'description': 'Compiler principles exam details',
        'importance': 2,
        'startDate': '2026-01-09T08:30:00.000',
        'deadline': '2026-01-09T10:30:00.000',
        'tags': ['study', 'exam'],
      });

      expect(result.title, 'Final exam');
      expect(result.description, 'Compiler principles exam details');
      expect(result.importance, 2);
      expect(result.startDate, DateTime.parse('2026-01-09T08:30:00.000'));
      expect(result.ddl, DateTime.parse('2026-01-09T10:30:00.000'));
      expect(result.tags, ['study', 'exam']);
    });

    test('uses defaults when fields are missing', () {
      final result = AIParseResult.fromJson({'title': 'Only title'});

      expect(result.title, 'Only title');
      expect(result.description, '');
      expect(result.importance, 1);
      expect(result.startDate, isNull);
      expect(result.ddl, isNull);
      expect(result.tags, isEmpty);
    });

    test('handles invalid date values safely', () {
      final result = AIParseResult.fromJson({
        'title': 'Bad dates',
        'startDate': 'not-a-date',
        'deadline': 'still-not-a-date',
      });

      expect(result.startDate, isNull);
      expect(result.ddl, isNull);
    });
  });

  group('AIService.parseTask', () {
    test('throws when AI configuration is missing', () async {
      SharedPreferences.setMockInitialValues({});
      final service = AIService();

      await expectLater(
        () => service.parseTask('Buy milk tomorrow'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('AI configuration missing'),
          ),
        ),
      );
    });

    test(
      'parses successful response and normalizes trailing slash in base URL',
      () async {
        SharedPreferences.setMockInitialValues({
          'ai_base_url': 'https://api.example.com/v1/',
          'ai_api_key': 'test-key',
          'ai_model': 'test-model',
        });

        final mockClient = MockClient((request) async {
          expect(
            request.url.toString(),
            'https://api.example.com/v1/chat/completions',
          );
          expect(request.headers['Authorization'], 'Bearer test-key');

          final responsePayload = {
            'choices': [
              {
                'message': {
                  'content':
                      '```json\n{"title":"Compiler Exam","description":"Room 105","importance":2,"startDate":null,"deadline":"2026-01-09T10:30:00.000","tags":["study"]}\n```',
                },
              },
            ],
          };

          return http.Response(jsonEncode(responsePayload), 200);
        });

        final service = AIService(httpClient: mockClient);
        final result = await service.parseTask('期末考试 1月9日 8:30-10:30 逸夫楼105');

        expect(result, isNotNull);
        expect(result!.title, 'Compiler Exam');
        expect(result.description, 'Room 105');
        expect(result.importance, 2);
        expect(result.ddl, DateTime.parse('2026-01-09T10:30:00.000'));
        expect(result.tags, ['study']);
      },
    );

    test('extracts JSON when backend includes extra text', () async {
      SharedPreferences.setMockInitialValues({
        'ai_base_url': 'https://api.example.com/v1/',
        'ai_api_key': 'test-key',
        'ai_model': 'test-model',
      });

      final mockClient = MockClient((request) async {
        final responsePayload = {
          'choices': [
            {
              'message': {
                'content':
                    'Sure! Here you go:\\n```json\\n{"title":"Buy milk","description":"","importance":1,"startDate":null,"deadline":null,"tags":[],"estimatedHours":0.25}\\n```\\n',
              },
            },
          ],
        };
        return http.Response(jsonEncode(responsePayload), 200);
      });

      final service = AIService(httpClient: mockClient);
      final result = await service.parseTask('Buy milk');

      expect(result, isNotNull);
      expect(result!.title, 'Buy milk');
      expect(result.importance, 1);
      expect(result.estimatedEffortHours, 0.25);
    });

    test('throws API Error when backend returns non-200', () async {
      SharedPreferences.setMockInitialValues({
        'ai_base_url': 'https://api.example.com/v1',
        'ai_api_key': 'test-key',
      });

      final mockClient = MockClient((request) async {
        return http.Response('server error', 500);
      });

      final service = AIService(httpClient: mockClient);

      await expectLater(
        () => service.parseTask('test input'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('API Error: 500'),
          ),
        ),
      );
    });

    test('rethrows timeout-related failures', () async {
      SharedPreferences.setMockInitialValues({
        'ai_base_url': 'https://api.example.com/v1',
        'ai_api_key': 'test-key',
      });

      final mockClient = MockClient((request) async {
        throw TimeoutException('network timeout');
      });

      final service = AIService(httpClient: mockClient);

      await expectLater(
        () => service.parseTask('test input'),
        throwsA(isA<TimeoutException>()),
      );
    });
  });

  group('AIService.parseTasks', () {
    test('parses list response into multiple tasks', () async {
      SharedPreferences.setMockInitialValues({
        'ai_base_url': 'https://api.example.com/v1/',
        'ai_api_key': 'test-key',
        'ai_model': 'test-model',
      });

      final mockClient = MockClient((request) async {
        final responsePayload = {
          'choices': [
            {
              'message': {
                'content':
                    '[{"title":"Task A","description":"","importance":1,"startDate":null,"deadline":null,"tags":["work"],"estimatedHours":1.0},{"title":"Task B","description":"","importance":0,"startDate":null,"deadline":null,"tags":[],"estimatedHours":0.5}]',
              },
            },
          ],
        };
        return http.Response(jsonEncode(responsePayload), 200);
      });

      final service = AIService(httpClient: mockClient);
      final results = await service.parseTasks('Task A; Task B');

      expect(results.length, 2);
      expect(results.first.title, 'Task A');
      expect(results.last.title, 'Task B');
    });
  });
}
