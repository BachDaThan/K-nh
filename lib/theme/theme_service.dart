import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const _kSeed = 'kinh_theme_seed';
  static const _kMode = 'kinh_theme_mode';
  static const _kBlur = 'kinh_theme_blur';
  static const _kPreset = 'kinh_theme_preset';
  static const _kSidebar = 'kinh_theme_sidebar';

  int seedColor = 0xFF6C8CFF;
  ThemeMode themeMode = ThemeMode.dark;
  double blurSigma = 12;
  String presetId = 'midnight';
  bool sidebarVisible = true;

  static const Map<String, Color> presets = {
    'midnight': Color(0xFF121212),
    'ocean': Color(0xFF0A1628),
    'forest': Color(0xFF0D1A12),
    'sunset': Color(0xFF1A1210),
    'mono': Color(0xFF1C1C1C),
    'slate': Color(0xFF151A21),
    'grape': Color(0xFF16121C),
  };

  static const Map<String, int> accentPresets = {
    'blue': 0xFF6C8CFF,
    'purple': 0xFFB388FF,
    'teal': 0xFF64FFDA,
    'amber': 0xFFFFC46C,
    'rose': 0xFFFF8A80,
    'lime': 0xFFB2FF59,
  };

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    seedColor = p.getInt(_kSeed) ?? 0xFF6C8CFF;
    blurSigma = p.getDouble(_kBlur) ?? 12;
    presetId = p.getString(_kPreset) ?? 'midnight';
    sidebarVisible = p.getBool(_kSidebar) ?? true;
    final mode = p.getString(_kMode) ?? 'dark';
    themeMode = switch (mode) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kSeed, seedColor);
    await p.setDouble(_kBlur, blurSigma);
    await p.setString(_kPreset, presetId);
    await p.setBool(_kSidebar, sidebarVisible);
    await p.setString(
      _kMode,
      switch (themeMode) {
        ThemeMode.light => 'light',
        ThemeMode.system => 'system',
        ThemeMode.dark => 'dark',
      },
    );
  }

  Color get scaffoldBg => presets[presetId] ?? presets['midnight']!;

  ThemeData buildTheme(Brightness brightness) {
    final seed = Color(seedColor);
    final bg =
        brightness == Brightness.dark ? scaffoldBg : const Color(0xFFF5F5F7);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: brightness),
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor:
            brightness == Brightness.dark ? Colors.white : Colors.black87,
      ),
    );
  }
}

class ThemeController extends ChangeNotifier {
  final ThemeService service = ThemeService();
  bool ready = false;

  Future<void> init() async {
    await service.load();
    ready = true;
    notifyListeners();
  }

  Future<void> setSeed(int argb) async {
    service.seedColor = argb;
    await service.save();
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    service.themeMode = mode;
    await service.save();
    notifyListeners();
  }

  Future<void> setPreset(String id) async {
    service.presetId = id;
    await service.save();
    notifyListeners();
  }

  Future<void> setBlur(double v) async {
    service.blurSigma = v.clamp(0, 24);
    await service.save();
    notifyListeners();
  }

  Future<void> setSidebarVisible(bool v) async {
    service.sidebarVisible = v;
    await service.save();
    notifyListeners();
  }
}

final themeController = ThemeController();
