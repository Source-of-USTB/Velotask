import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

export 'package:logging/logging.dart';

/// Global logger configuration and utilities
class AppLogger {
  static final Logger root = Logger.root;

  static void setup({Level level = Level.ALL}) {
    // In release mode, we usually want to disable logging or only log SEVERE errors.
    if (kReleaseMode) {
      root.level = Level.OFF;
      return;
    }

    root.level = level;
    root.onRecord.listen((record) {
      final emoji = _getEmoji(record.level);
      // Format time as HH:mm:ss.SSS
      final time = record.time.toString().split(' ').last.substring(0, 12);
      final name = record.loggerName.padRight(12);

      debugPrint('$emoji [$time] $name | ${record.message}');

      if (record.error != null) {
        debugPrint('   └─ ❌ Error: ${record.error}');
      }
      if (record.stackTrace != null) {
        debugPrint('   └─ 📜 StackTrace: ${record.stackTrace}');
      }
    });
  }

  static String _getEmoji(Level level) {
    if (level >= Level.SEVERE) return '🚫';
    if (level >= Level.WARNING) return '⚠️';
    if (level >= Level.INFO) return '💡';
    if (level >= Level.CONFIG) return '⚙️';
    return '🔍';
  }

  static Logger getLogger(String name) {
    return Logger(name);
  }
}
