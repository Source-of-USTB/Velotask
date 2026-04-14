import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:velotask/l10n/app_localizations.dart';
import 'package:velotask/models/todo.dart';
import 'package:velotask/utils/logger.dart';
import 'package:velotask/utils/priority_engine.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  static const String _channelId = 'velotask_reminders';
  static const String _channelName = 'Task Reminders';
  static const String _channelDescription =
      'Reminders for deadlines and daily summaries';
  static const Duration _minResyncInterval = Duration(seconds: 3);

  static const int _dailySummaryId = 888888;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  DateTime? _lastResyncAt;
  String? _lastResyncFingerprint;
  Map<int, String> _scheduledTaskFingerprints = <int, String>{};
  String? _dailySummaryFingerprint;
  bool _hasHydratedPendingNotifications = false;
  static final Logger _logger = AppLogger.getLogger('NotificationService');

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      tz.initializeTimeZones();
      final dynamic timeZoneResult = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = switch (timeZoneResult) {
        String value => value,
        TimezoneInfo value => value.identifier,
        _ => 'UTC',
      };
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      _logger.warning('Failed to initialize timezone: $e');
      // Fallback to UTC
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        _logger.info('Notification clicked: ${details.payload}');
      },
    );

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
    _logger.info('NotificationService initialized');
  }

  Future<void> syncForTodos(List<Todo> todos, AppLocalizations l10n) async {
    if (!_initialized) {
      await initialize();
    }

    final now = DateTime.now();
    final fingerprint = _buildResyncFingerprint(todos, l10n.localeName);
    final shouldSkip =
        _lastResyncFingerprint == fingerprint &&
        _lastResyncAt != null &&
        now.difference(_lastResyncAt!) < _minResyncInterval;
    if (shouldSkip) {
      _logger.fine('Skip notification resync: unchanged snapshot in cooldown.');
      return;
    }

    int activeCount = 0;
    final desiredTaskFingerprints = <int, String>{};

    for (final todo in todos) {
      if (todo.isCompleted) continue;

      activeCount++;

      // Schedule DDL reminder if DDL is in the future
      if (todo.ddl != null && todo.ddl!.isAfter(now)) {
        final reminderPlan = _buildTaskReminderPlan(todo, l10n);
        if (reminderPlan == null) {
          continue;
        }
        desiredTaskFingerprints[todo.id] = reminderPlan.fingerprint;
        final previousFingerprint = _scheduledTaskFingerprints[todo.id];
        if (previousFingerprint != reminderPlan.fingerprint) {
          await _plugin.cancel(todo.id);
          await _scheduleTaskReminder(todo.id, reminderPlan);
        }
      }
    }

    if (!_hasHydratedPendingNotifications) {
      final pending = await _plugin.pendingNotificationRequests();
      for (final item in pending) {
        if (item.id == _dailySummaryId) {
          continue;
        }
        if (!desiredTaskFingerprints.containsKey(item.id)) {
          await _plugin.cancel(item.id);
        }
      }
      _hasHydratedPendingNotifications = true;
    }

    final staleIds = _scheduledTaskFingerprints.keys
        .where((id) => !desiredTaskFingerprints.containsKey(id))
        .toList();
    for (final staleId in staleIds) {
      await _plugin.cancel(staleId);
    }

    _scheduledTaskFingerprints = desiredTaskFingerprints;

    final dailyFingerprint = '${l10n.localeName}|$activeCount';
    if (_dailySummaryFingerprint != dailyFingerprint) {
      await _plugin.cancel(_dailySummaryId);
      await _scheduleDailySummary(activeCount, l10n);
      _dailySummaryFingerprint = dailyFingerprint;
    }

    _lastResyncFingerprint = fingerprint;
    _lastResyncAt = now;
  }

  String _buildResyncFingerprint(List<Todo> todos, String localeName) {
    final relevant =
        todos
            .map(
              (todo) => [
                todo.id,
                todo.isCompleted,
                todo.ddl?.millisecondsSinceEpoch ?? -1,
                todo.title,
                todo.importance,
                todo.estimatedEffortHours ?? -1,
              ].join('#'),
            )
            .toList()
          ..sort();
    return '$localeName|${relevant.join('|')}';
  }

  _TaskReminderPlan? _buildTaskReminderPlan(Todo todo, AppLocalizations l10n) {
    try {
      final now = tz.TZDateTime.now(tz.local);
      final ddl = tz.TZDateTime.from(todo.ddl!, tz.local);

      // 1. Calculate the ideal reminder time based on Urgency
      // We want to remind when the task enters "High" urgency (0.7)
      // or "Critical" urgency (0.9), or just before deadline.

      tz.TZDateTime? scheduledDate;

      // Check time for Urgency 0.7 (High)
      var highUrgencyTime = _findTimeForUrgency(todo, 0.7);
      if (highUrgencyTime != null && highUrgencyTime.isAfter(now)) {
        scheduledDate = highUrgencyTime;
      } else {
        // Fallback: Check time for Urgency 0.85 (Critical)
        var criticalUrgencyTime = _findTimeForUrgency(todo, 0.85);
        if (criticalUrgencyTime != null && criticalUrgencyTime.isAfter(now)) {
          scheduledDate = criticalUrgencyTime;
        } else {
          // Fallback: 1 hour before deadline
          var oneHourBefore = ddl.subtract(const Duration(hours: 1));
          if (oneHourBefore.isAfter(now)) {
            scheduledDate = oneHourBefore;
          }
        }
      }

      if (scheduledDate == null) {
        _logger.fine('No suitable future reminder time for "${todo.title}"');
        return null;
      }

      final UrgencyBand band = PriorityEngine.urgencyBand(
        todo,
        now: scheduledDate,
      );
      final String urgencyText = switch (band) {
        UrgencyBand.impossible => l10n.urgencyImpossible,
        UrgencyBand.high => l10n.urgencyHigh,
        UrgencyBand.medium => l10n.urgencyMedium,
        UrgencyBand.relaxed => l10n.urgencyRelaxed,
      };

      final title = l10n.notifyPriorityTitle;
      final body = '${todo.title} • ${l10n.urgencyLabel}: $urgencyText';
      return _TaskReminderPlan(
        scheduledDate: scheduledDate,
        title: title,
        body: body,
        fingerprint:
            '${scheduledDate.millisecondsSinceEpoch}|${todo.title}|$urgencyText|${l10n.localeName}',
      );
    } catch (e) {
      _logger.warning('Failed to schedule reminder for todo ${todo.id}: $e');
      return null;
    }
  }

  Future<void> _scheduleTaskReminder(int todoId, _TaskReminderPlan plan) async {
    try {
      await _plugin.zonedSchedule(
        todoId,
        plan.title,
        plan.body,
        plan.scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'todo_$todoId',
      );
      _logger.fine(
        'Scheduled exact reminder for todo $todoId at ${plan.scheduledDate} (Urgency based)',
      );
    } catch (e) {
      if (!_isExactAlarmsNotPermittedError(e)) {
        rethrow;
      }

      _logger.warning(
        'Exact alarms are not permitted; falling back to inexact reminder for todo $todoId',
      );
      await _plugin.zonedSchedule(
        todoId,
        plan.title,
        plan.body,
        plan.scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'todo_$todoId',
      );
      _logger.fine(
        'Scheduled inexact reminder for todo $todoId at ${plan.scheduledDate}',
      );
    }
  }

  bool _isExactAlarmsNotPermittedError(Object error) {
    if (error is! PlatformException) {
      return false;
    }
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();
    return code.contains('exact_alarms_not_permitted') ||
        message.contains('exact alarms are not permitted');
  }

  /// Finds the approximate time when the task reaches the target urgency.
  /// Returns null if urgency is never reached or calculation fails.
  tz.TZDateTime? _findTimeForUrgency(Todo todo, double targetUrgency) {
    if (todo.ddl == null) return null;

    // Binary search range: 0 to 30 days before DDL
    double minMinutes = 0;
    double maxMinutes = 30 * 24 * 60;

    // Tolerance for binary search
    const double epsilon = 0.05;

    // We are searching for `minutesBeforeDDL`
    // Function: urgency(ddl - minutes)
    // Urgency increases as minutes -> 0.

    // quick check at max range (early)
    if (_getUrgencyAt(todo, maxMinutes) >= targetUrgency) {
      // already high urgency even 30 days out? (unlikely for normal tasks)
      return tz.TZDateTime.from(
        todo.ddl!.subtract(Duration(minutes: maxMinutes.toInt())),
        tz.local,
      );
    }

    // quick check at min range (deadline)
    if (_getUrgencyAt(todo, minMinutes) < targetUrgency) {
      // never reaches urgency?
      return null;
    }

    for (int i = 0; i < 20; i++) {
      // 20 iterations is precise enough
      double mid = (minMinutes + maxMinutes) / 2;
      double u = _getUrgencyAt(todo, mid);

      if ((u - targetUrgency).abs() < epsilon) {
        return tz.TZDateTime.from(
          todo.ddl!.subtract(Duration(minutes: mid.toInt())),
          tz.local,
        );
      }

      if (u < targetUrgency) {
        // Urgency is too low, we need to be closer to deadline (less minutes)
        maxMinutes = mid;
      } else {
        // Urgency is too high, we need to be further from deadline (more minutes)
        minMinutes = mid;
      }
    }

    return tz.TZDateTime.from(
      todo.ddl!.subtract(Duration(minutes: minMinutes.toInt())),
      tz.local,
    );
  }

  double _getUrgencyAt(Todo todo, double minutesBeforeDDL) {
    final checkTime = todo.ddl!.subtract(
      Duration(minutes: minutesBeforeDDL.toInt()),
    );
    return PriorityEngine.urgency(todo, now: checkTime);
  }

  Future<void> _scheduleDailySummary(int count, AppLocalizations l10n) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      // Schedule for 09:00 AM
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        9,
        0,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        _dailySummaryId,
        l10n.dailyReminderTitle,
        l10n.dailyReminderBody(count),
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'daily_summary',
      );
      _logger.info('Scheduled daily summary at $scheduledDate');
    } catch (e) {
      _logger.warning('Failed to schedule daily summary: $e');
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}

class _TaskReminderPlan {
  final tz.TZDateTime scheduledDate;
  final String title;
  final String body;
  final String fingerprint;

  const _TaskReminderPlan({
    required this.scheduledDate,
    required this.title,
    required this.body,
    required this.fingerprint,
  });
}
