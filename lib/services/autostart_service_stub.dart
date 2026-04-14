class AutostartService {
  static bool get isSupported => false;

  static Future<void> initialize() async {}

  static Future<bool> isEnabled() async => false;

  static Future<void> setEnabled(bool value) async {}
}
