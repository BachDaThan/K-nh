import 'package:shared_preferences/shared_preferences.dart';
import '../models/doh_provider.dart';

/// Quản lý lựa chọn DoH (DNS-over-HTTPS).
///
/// Lưu ý kỹ thuật: System WebView / WebView2 không cho phép set DoH
/// trực tiếp như GeckoView. Implementation hiện tại lưu preference
/// và (nếu có thể) truyền hint qua proxy / user-script.
/// Khi chuyển sang GeckoBrowserEngine, sẽ inject DoH thật ở tầng network.
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

  Future<void> setCustomUrl(String url) async {
    final provider = DohProvider(
      id: 'custom',
      name: 'DoH tùy chỉnh',
      url: url.trim(),
      isCustom: true,
    );
    await setProvider(provider);
  }
}
