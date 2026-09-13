import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Nhân trình duyệt.
/// - [chromium]: System WebView / WebView2 (ổn định, mặc định)
/// - [gecko]: GeckoView qua plugin thử nghiệm (Android only, WIP)
enum BrowserEngineKind { chromium, gecko }

class EnginePreference {
  static const _key = 'kinh_browser_engine_kind';

  BrowserEngineKind kind = BrowserEngineKind.chromium;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(_key);
    if (v == 'gecko') {
      kind = BrowserEngineKind.gecko;
    } else {
      kind = BrowserEngineKind.chromium;
    }
  }

  Future<void> setKind(BrowserEngineKind k) async {
    // Windows / desktop: chỉ Chromium
    if (k == BrowserEngineKind.gecko &&
        (kIsWeb ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      kind = BrowserEngineKind.chromium;
    } else {
      kind = k;
    }
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, kind.name);
  }

  bool get geckoRequested => kind == BrowserEngineKind.gecko;

  String get label {
    switch (kind) {
      case BrowserEngineKind.chromium:
        return 'Chromium / System WebView';
      case BrowserEngineKind.gecko:
        return 'GeckoView (thử nghiệm)';
    }
  }
}

final enginePreference = EnginePreference();
