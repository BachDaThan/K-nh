import 'package:flutter/foundation.dart';

import '../services/engine_preference.dart';
import 'gecko_register.dart' if (dart.library.html) 'gecko_register_stub.dart';

/// Đăng ký platform WebView. Gecko chỉ Android; lỗi → Chromium.
Future<String> bootstrapBrowserEngine() async {
  await enginePreference.load();
  if (!enginePreference.geckoRequested) {
    return 'chromium';
  }
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    await enginePreference.setKind(BrowserEngineKind.chromium);
    return 'chromium (gecko chỉ Android)';
  }
  try {
    await registerGeckoWebViewPlatform();
    return 'gecko';
  } catch (e) {
    await enginePreference.setKind(BrowserEngineKind.chromium);
    return 'chromium (gecko lỗi: $e)';
  }
}
