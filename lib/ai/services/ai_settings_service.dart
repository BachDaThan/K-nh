import 'package:shared_preferences/shared_preferences.dart';

/// API key AI cá nhân — lưu local, không gửi server Kính.
class AiSettingsService {
  static const _kKey = 'kinh_ai_api_key';
  static const _kBase = 'kinh_ai_base_url';
  static const _kModel = 'kinh_ai_model';

  String apiKey = '';
  String baseUrl = 'https://api.openai.com/v1';
  String model = 'gpt-4o-mini';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    apiKey = p.getString(_kKey) ?? '';
    baseUrl = p.getString(_kBase) ?? 'https://api.openai.com/v1';
    model = p.getString(_kModel) ?? 'gpt-4o-mini';
  }

  Future<void> save({
    String? apiKey,
    String? baseUrl,
    String? model,
  }) async {
    final p = await SharedPreferences.getInstance();
    if (apiKey != null) {
      this.apiKey = apiKey;
      await p.setString(_kKey, apiKey);
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
