import 'package:shared_preferences/shared_preferences.dart';
import '../models/doh_provider.dart';

/// Quản lý lựa chọn DoH (DNS-over-HTTPS).
/// Preference lưu local. System WebView chưa inject DoH tầng OS —
/// vẫn lưu để UI/Gecko sau này dùng.
class DohService {
  static const _keyProviderId = 'doh_provider_id';
  static const _keyCustomUrl = 'doh_custom_url';

  DohProvider _current = DohProvider.presets.first;
  String? _customUrl;

  DohProvider get current => _current;
  String? get customUrl => _customUrl;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_keyProviderId) ?? 'cloudflare';
    _customUrl = prefs.getString(_keyCustomUrl);

    if (id == 'custom' && _customUrl != null && _customUrl!.isNotEmpty) {
      _current = DohProvider(
        id: 'custom',
        name: 'DoH tùy chỉnh',
        url: _customUrl!,
        isCustom: true,
      );
    } else {
      _current = DohProvider.presets.firstWhere(
        (p) => p.id == id,
        orElse: () => DohProvider.presets.first,
      );
    }
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

  /// Chuẩn hoá URL DoH: thêm https:// nếu thiếu, bỏ khoảng trắng.
  static String? normalizeUrl(String raw) {
    var u = raw.trim();
    if (u.isEmpty) return null;
    if (!u.contains('://')) {
      u = 'https://$u';
    }
    final uri = Uri.tryParse(u);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    if (uri.scheme != 'https' && uri.scheme != 'http') return null;
    // DoH endpoint nên là https
    if (uri.scheme == 'http') {
      u = u.replaceFirst('http://', 'https://');
    }
    return u;
  }

  /// Trả về null nếu OK, hoặc chuỗi lỗi tiếng Việt.
  Future<String?> setCustomUrl(String raw) async {
    final url = normalizeUrl(raw);
    if (url == null) {
      return 'URL không hợp lệ. Ví dụ: https://dns.nextdns.io/abc123';
    }
    await setProvider(DohProvider(
      id: 'custom',
      name: 'DoH tùy chỉnh',
      url: url,
      isCustom: true,
    ));
    return null;
  }
}
