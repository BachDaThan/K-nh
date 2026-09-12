import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const _kSeed = 'kinh_theme_seed';
  static const _kMode = 'kinh_theme_mode';
  static const _kBlur = 'kinh_theme_blur';
  static const _kPreset = 'kinh_theme_preset';
  static const _kSidebar = 'kinh_theme_sidebar';

  int seedColor = 0xFF7C9CFF;
  ThemeMode themeMode = ThemeMode.dark;
  double blurSigma = 14;
  String presetId = 'aurora';
  bool sidebarVisible = true;

  static const Map<String, Color> presets = {
    'aurora': Color(0xFF0B1020),
    'midnight': Color(0xFF121212),
    'ocean': Color(0xFF061525),
    'forest': Color(0xFF0A1610),
    'sunset': Color(0xFF1A0E0C),
    'neon': Color(0xFF0A0A14),
    'mono': Color(0xFF1C1C1C),
  };

  static const Map<String, int> accentPresets = {
    'blue': 0xFF7C9CFF,
    'purple': 0xFFC4A0FF,
    'cyan': 0xFF5CFFE7,
    'amber': 0xFFFFD27A,
    'rose': 0xFFFF8FB0,
    'lime': 0xFFB8FF6A,
    'magenta': 0xFFFF6AD5,
  };

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    seedColor = p.getInt(_kSeed) ?? 0xFF7C9CFF;
    blurSigma = p.getDouble(_kBlur) ?? 14;
    presetId = p.getString(_kPreset) ?? 'aurora';
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

  Color get scaffoldBg => presets[presetId] ?? presets['aurora']!;

  ThemeData buildTheme(Brightness brightness) {
    final seed = Color(seedColor);
    final bg =
        brightness == Brightness.dark ? scaffoldBg : const Color(0xFFF4F6FB);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: brightness),
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: bg.withOpacity(0.92),
        elevation: 0,
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
