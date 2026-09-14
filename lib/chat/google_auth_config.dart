import 'package:shared_preferences/shared_preferences.dart';

/// Mặc định từ repo (có thể để trống/REPLACE).
/// User có thể **ghi đè trong app** (Hướng dẫn Cộng đồng) → lưu SharedPreferences.
const String kGoogleWebClientIdBuiltIn =
    '886555523620-o29gm3mrme1917hr5bf6hp1jkc03bvui.apps.googleusercontent.com';

const _prefsKey = 'kinh_google_web_client_id';

String? _overrideId;

/// ID đang dùng (override app > built-in).
String get kGoogleWebClientId {
  final o = _overrideId?.trim();
  if (o != null && o.isNotEmpty && !o.contains('REPLACE')) return o;
  return kGoogleWebClientIdBuiltIn;
}

Future<void> loadGoogleWebClientIdOverride() async {
  final p = await SharedPreferences.getInstance();
  _overrideId = p.getString(_prefsKey);
}

Future<void> saveGoogleWebClientIdOverride(String id) async {
  final p = await SharedPreferences.getInstance();
  final t = id.trim();
  if (t.isEmpty) {
    await p.remove(_prefsKey);
    _overrideId = null;
  } else {
    await p.setString(_prefsKey, t);
    _overrideId = t;
  }
}
