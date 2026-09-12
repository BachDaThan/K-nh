import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'theme/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await themeController.init();
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
          title: 'Kính',
          debugShowCheckedModeBanner: false,
          themeMode: s.themeMode,
          theme: s.buildTheme(Brightness.light),
          darkTheme: s.buildTheme(Brightness.dark),
          home: const DashboardScreen(),
        );
      },
    );
  }
}
