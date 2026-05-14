import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

export 'package:logging/logging.dart';

class AppLogger {
  static final Logger root = Logger.root;

  static const _levelPad = 5;
  static const _modulePad = 24;

  static void setup({Level level = Level.ALL}) {
    if (kReleaseMode) {
      root.level = Level.OFF;
      return;
    }

    root.level = level;
    root.onRecord.listen((record) {
      final buf = StringBuffer();

      // Line 1: 12:34:56.789 LEVEL ModuleName             message error=Type
      buf.write(_fmtTime(record.time));
      buf.write(' ');
      buf.write(_levelLabel(record.level).padRight(_levelPad));
      buf.write(' ');
      buf.write(_clipModule(record.loggerName).padRight(_modulePad));
      buf.write(' ');
      buf.write(record.message);

      final error = record.error;
      final st = record.stackTrace;

      if (error != null) {
        buf.write(' error=');
        buf.write(error.runtimeType.toString());
      }

      // Reason from error
      if (error != null) {
        buf.writeln();
        buf.write('  reason:');
        buf.writeln();
        buf.write('    ${error.toString()}');
      }

      // Stack trace (multi-line)
      if (st != null && record.level >= Level.WARNING) {
        _writeStack(buf, st.toString());
      }

      debugPrint(buf.toString());
    });
  }

  static void _writeStack(StringBuffer buf, String raw) {
    final lines = raw.trim().split('\n');
    final frameRe = RegExp(r'^(#\d+)\s+(.*)');
    final appFrames = <String>[];
    final allFrames = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.startsWith('<')) continue;

      final m = frameRe.firstMatch(trimmed);
      if (m == null) continue;

      final num = m.group(1)!;
      final detail = m.group(2)!;

      final parenIdx = detail.indexOf(' (');
      final method = parenIdx >= 0 ? detail.substring(0, parenIdx) : detail;
      final loc = parenIdx >= 0
          ? _shortLocation(detail.substring(parenIdx + 2, detail.length - 1))
          : '';

      final formatted = '    $num $method\n'
          '       $loc';

      final isApp = detail.contains('package:velotask/');
      if (isApp) {
        appFrames.add(formatted);
      }
      allFrames.add(formatted);
    }

    if (appFrames.isNotEmpty) {
      buf.writeln();
      buf.writeln('  app_stack:');
      buf.write(appFrames.join('\n'));
    }

    buf.writeln();
    buf.writeln('  full_stack:');
    buf.write(allFrames.join('\n'));
  }

  /// Extract short location: "velotask/services/file.dart:12:34" -> "services/file.dart:12:34"
  static String _shortLocation(String loc) {
    final m = RegExp(r'^package:(\w+)/(.+)$').firstMatch(loc);
    if (m != null) {
      final pkg = m.group(1)!;
      final path = m.group(2)!;
      if (pkg == 'velotask') return path;
      return '$pkg/$path';
    }
    // dart: core libs or other URI schemes
    if (loc.startsWith('dart:')) return loc;
    return loc;
  }

  static String _fmtTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    final ms = t.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  static String _clipModule(String name) {
    if (name.length <= _modulePad) return name;
    return '${name.substring(0, _modulePad - 1)}~';
  }

  static String _levelLabel(Level level) {
    if (level >= Level.SEVERE) return 'ERROR';
    if (level >= Level.WARNING) return 'WARN';
    if (level >= Level.INFO) return 'INFO';
    if (level >= Level.CONFIG) return 'CONF';
    return 'DEBUG';
  }

  static Logger getLogger(String name) {
    return Logger(name);
  }
}
