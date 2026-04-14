import 'dart:io';

import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AutostartService {
  static bool get isSupported => Platform.isWindows;

  static Future<void> initialize() async {
    if (!isSupported) return;
    final packageInfo = await PackageInfo.fromPlatform();
    launchAtStartup.setup(
      appName: packageInfo.appName,
      appPath: Platform.resolvedExecutable,
    );
  }

  static Future<bool> isEnabled() async {
    if (!isSupported) return false;
    return await launchAtStartup.isEnabled();
  }

  static Future<void> setEnabled(bool value) async {
    if (!isSupported) return;
    if (value) {
      await launchAtStartup.enable();
    } else {
      await launchAtStartup.disable();
    }
  }
}
