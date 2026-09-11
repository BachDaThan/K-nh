import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KinhApp());
}

/// App gốc "Kính" — Dashboard / Trình duyệt All-in-One.
///
/// Bước 1: khung Bento Grid Dashboard.
/// Bước 2: Browser engine (Chromium/WebView2) qua abstraction BrowserEngine,
///         Omnibox, Tab, Bookmark, Download, DoH, Search Diversity.
class KinhApp extends StatelessWidget {
  const KinhApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kính',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C8CFF),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      ),
      home: const DashboardScreen(),
    );
  }
}
