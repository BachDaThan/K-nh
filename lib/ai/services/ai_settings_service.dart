import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// API key AI cá nhân — lưu local, không gửi server Kính.
///
/// apiKey lưu qua FlutterSecureStorage (mã hóa bằng Android KeyStore /
/// iOS Keychain) — KHÔNG dùng SharedPreferences vì đó là file XML
/// plaintext, có thể bị đọc nếu máy root hoặc app khác có quyền truy cập.
/// baseUrl/model không nhạy cảm nên vẫn để SharedPreferences như cũ.
class AiSettingsService {
  static const _kKey = 'kinh_ai_api_key';
  static const _kBase = 'kinh_ai_base_url';
  static const _kModel = 'kinh_ai_model';

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String apiKey = '';
  String baseUrl = 'https://api.openai.com/v1';
  String model = 'gpt-4o-mini';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    apiKey = await _secureStorage.read(key: _kKey) ?? '';
    baseUrl = p.getString(_kBase) ?? 'https://api.openai.com/v1';
    model = p.getString(_kModel) ?? 'gpt-4o-mini';

    // Migration 1 lần: nếu còn key cũ trong SharedPreferences (bản trước khi
    // có secure storage), chuyển sang secure storage rồi xóa bản plaintext.
    final legacyKey = p.getString(_kKey);
    if (legacyKey != null && legacyKey.isNotEmpty && apiKey.isEmpty) {
      apiKey = legacyKey;
      await _secureStorage.write(key: _kKey, value: legacyKey);
    }
    if (legacyKey != null) {
      await p.remove(_kKey);
    }
  }

  Future<void> save({
    String? apiKey,
    String? baseUrl,
    String? model,
  }) async {
    final p = await SharedPreferences.getInstance();
    if (apiKey != null) {
      this.apiKey = apiKey;
      if (apiKey.isEmpty) {
        await _secureStorage.delete(key: _kKey);
      } else {
        await _secureStorage.write(key: _kKey, value: apiKey);
      }
    }
    if (baseUrl != null) {
      this.baseUrl = baseUrl.trim().replaceAll(RegExp(r'/$'), '');
      await p.setString(_kBase, this.baseUrl);
    }
    if (model != null) {
      this.model = model.trim();
      await p.setString(_kModel, this.model);
    }
  }

  bool get hasKey => apiKey.trim().isNotEmpty;
}
