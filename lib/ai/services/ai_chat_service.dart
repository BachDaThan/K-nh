import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_settings_service.dart';

class AiChatService {
  final AiSettingsService settings;

  AiChatService(this.settings);

  /// Gọi chat completions (OpenAI-compatible: OpenAI, Groq, Together, local LM Studio…)
  Future<String> complete({
    required String system,
    required String user,
  }) async {
    if (!settings.hasKey) {
      throw Exception('Chưa nhập API key. Vào ⚙️ AI Settings.');
    }
    final uri = Uri.parse('${settings.baseUrl}/chat/completions');
    final res = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${settings.apiKey}',
          },
          body: jsonEncode({
            'model': settings.model,
            'messages': [
              {'role': 'system', 'content': system},
              {'role': 'user', 'content': user},
            ],
            'temperature': 0.4,
          }),
        )
        .timeout(const Duration(seconds: 90));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('API ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw Exception('API không trả về choices');
    }
    final msg = choices.first['message'] as Map<String, dynamic>?;
    return (msg?['content'] as String?)?.trim() ?? '';
  }
}
