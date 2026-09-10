import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const KinhApp());
}

/// App gốc "Kính" — Dashboard/Trình duyệt All-in-One.
/// Bước 1: khung Bento Grid Dashboard, Dark Mode.
/// Các cụm tính năng khác (browser engine, AI builder, sync...)
/// sẽ được thêm dần ở các bước tiếp theo, mỗi bước build được ngay.
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
