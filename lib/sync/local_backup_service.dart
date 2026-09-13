import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Backup/restore cấu hình local (bookmarks prefs keys, theme, doh…) —
/// 100% client-side, không server. Người dùng copy JSON hoặc chia sẻ tay.
class LocalBackupService {
  /// Các prefix/key an toàn để export (không export secure storage API keys).
  static const exportKeys = [
    'doh_provider_id',
    'doh_custom_url',
    'kinh_theme_seed',
    'kinh_theme_mode',
    'kinh_theme_blur',
    'kinh_theme_preset',
    'kinh_theme_sidebar',
    'kinh_pinned_apps',
    'kinh_bookmarks',
    'kinh_diversity_index',
  ];

  Future<String> exportJson() async {
    final p = await SharedPreferences.getInstance();
    final map = <String, dynamic>{
      'app': 'kinh',
      'format': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'data': <String, dynamic>{},
    };
    final data = map['data'] as Map<String, dynamic>;
    for (final k in exportKeys) {
      if (!p.containsKey(k)) continue;
      data[k] = p.get(k);
    }
    // Also dump keys starting with kinh_
    for (final k in p.getKeys()) {
      if (k.startsWith('kinh_') || k.startsWith('doh_')) {
        data[k] = p.get(k);
      }
    }
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  Future<int> importJson(String raw) async {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final data = (decoded['data'] as Map?)?.cast<String, dynamic>() ?? {};
    final p = await SharedPreferences.getInstance();
    var n = 0;
    for (final e in data.entries) {
      final v = e.value;
      if (v is bool) {
        await p.setBool(e.key, v);
      } else if (v is int) {
        await p.setInt(e.key, v);
      } else if (v is double) {
        await p.setDouble(e.key, v);
      } else if (v is String) {
        await p.setString(e.key, v);
      } else if (v is List) {
        await p.setStringList(e.key, v.map((x) => '$x').toList());
      } else {
        continue;
      }
      n++;
    }
    return n;
  }
}
