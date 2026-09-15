import 'package:shared_preferences/shared_preferences.dart';
import '../models/doh_provider.dart';

/// DoH trong app (lưu local).
/// System WebView dùng DNS của máy — không đổi Private DNS toàn thiết bị.
/// Bật/tắt = preference cho UI + sẵn sàng khi engine hỗ trợ inject.
class DohService {
  static const _keyEnabled = 'doh_enabled_v1';
  static const _keyProviderId = 'doh_provider_id';
  static const _keyCustomUrl = 'doh_custom_url';

  bool enabled = true;
  DohProvider _current = DohProvider.presets.first;
  String? _customUrl;

  DohProvider get current => _current;
  String? get customUrl => _customUrl;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    enabled = prefs.getBool(_keyEnabled) ?? true;
    final id = prefs.getString(_keyProviderId) ?? 'cloudflare';
    _customUrl = prefs.getString(_keyCustomUrl);

    if (id == 'custom' && _customUrl != null && _customUrl!.isNotEmpty) {
      _current = DohProvider(
        id: 'custom',
        name: 'Tùy chỉnh',
        url: _customUrl!,
        subtitle: 'URL nhà cung cấp DoH',
        isCustom: true,
      );
    } else {
      _current = DohProvider.presets.firstWhere(
        (p) => p.id == id,
        orElse: () => DohProvider.presets.first,
      );
    }
  }

  Future<void> setEnabled(bool v) async {
    enabled = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, v);
  }

  Future<void> setProvider(DohProvider provider) async {
    _current = provider;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProviderId, provider.id);
    if (provider.isCustom) {
      _customUrl = provider.url;
      await prefs.setString(_keyCustomUrl, provider.url);
    }
  }

  static String? normalizeUrl(String raw) {
    var u = raw.trim();
    if (u.isEmpty) return null;
    if (!u.contains('://')) {
      u = 'https://$u';
    }
    final uri = Uri.tryParse(u);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    if (uri.scheme != 'https' && uri.scheme != 'http') return null;
    if (uri.scheme == 'http') {
      u = u.replaceFirst('http://', 'https://');
    }
    return u;
  }

  Future<String?> setCustomUrl(String raw) async {
    final url = normalizeUrl(raw);
    if (url == null) {
      return 'URL không hợp lệ. Ví dụ: https://dns.nextdns.io/abc123';
    }
    await setProvider(DohProvider(
      id: 'custom',
      name: 'Tùy chỉnh',
      url: url,
      subtitle: 'URL nhà cung cấp DoH',
      isCustom: true,
    ));
    return null;
  }
}
