import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:velotask/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velotask/screens/main_screen.dart';
import 'package:velotask/theme/app_theme.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);
// 自动跟随系统颜色
final ValueNotifier<Locale?> localeNotifier = ValueNotifier(null);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Load Theme
  final savedTheme = prefs.getString('theme_mode');
  if (savedTheme != null) {
    themeNotifier.value = ThemeMode.values.firstWhere(
      (e) => e.toString() == savedTheme,
      orElse: () => ThemeMode.system,
    );
  }

  // Load Locale
  final savedLocale = prefs.getString('locale');
  if (savedLocale != null) {
    localeNotifier.value = Locale(savedLocale);
  }

  runApp(const MyApp()); //
}

// 根组件
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      // 监听
      listenable: Listenable.merge([themeNotifier, localeNotifier]),
      builder: (context, child) {
        return MaterialApp(
          title: 'Velotask',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeNotifier.value,
          locale: localeNotifier.value,
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
