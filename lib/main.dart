import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:velotask/l10n/app_localizations.dart';
import 'package:velotask/screens/main_screen.dart';
import 'package:velotask/services/app_settings_controller.dart';
import 'package:velotask/services/color_config_manager.dart';
import 'package:velotask/theme/app_theme.dart';
import 'package:velotask/utils/logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.setup();

  await ColorConfigManager.instance.init();
  await AppSettingsController.load();

  runApp(const MyApp());
}

// 根组件
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      // 监听
      listenable: Listenable.merge([
        AppSettingsController.themeNotifier,
        AppSettingsController.localeNotifier,
        ColorConfigManager.instance,
      ]),
      builder: (context, child) {
        return MaterialApp(
          title: 'Velotask',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: AppSettingsController.themeNotifier.value,
          locale: AppSettingsController.localeNotifier.value,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('zh'), // Chinese
          ],
          home: const MainScreen(), // 控制页面布局
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
