import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'theme/theme_service.dart';
import 'config/app_edition.dart';
import 'browser/services/safe_browsing_service.dart';
import 'perf/performance_service.dart';
import 'browser/services/search_engine_service.dart';
import 'browser/services/adblock_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await themeController.init();
  await safeBrowsingService.load();
  await performanceService.load();
  await searchEngineService.load();
  await adblockService.load();
  runApp(const KinhApp());
}

class KinhApp extends StatelessWidget {
  const KinhApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        final s = themeController.service;
        return MaterialApp(
          title: AppEdition.displayName,
          debugShowCheckedModeBanner: false,
          themeMode: s.themeMode,
          theme: s.buildTheme(Brightness.light),
          darkTheme: s.buildTheme(Brightness.dark),
          home: const SplashScreen(),
        );
      },
    );
  }
}
