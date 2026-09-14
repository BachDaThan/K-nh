import 'package:shared_preferences/shared_preferences.dart';

/// 3 mức giống Chrome — **local**, không gửi URL lên Google, không API key.
enum SafeBrowsingLevel {
  /// Không chặn thêm (vẫn có adblock nếu bật riêng).
  off,

  /// Chặn host độc hại đã biết + cảnh báo HTTP form.
  standard,

  /// Siết hơn: thêm mẫu lừa đảo, IP trần, TLD rủi ro, đuôi tải nguy hiểm.
  enhanced,
}

class SafeBrowsingService {
  static const _key = 'kinh_safe_browsing_level';
  SafeBrowsingLevel level = SafeBrowsingLevel.standard;

  /// Host độc hại / lừa đảo phổ biến (danh sách cục bộ, rút gọn).
  static const _badHosts = {
    'malware.testing.google.test',
    'testsafebrowsing.appspot.com',
    'iphone-security.org',
    'account-google.com',
    'secure-appleid.com',
    'facebook-login.tk',
    'paypal-secure.tk',
  };

  static const _riskyTlds = {
    '.zip',
    '.mov',
    '.tk',
    '.gq',
    '.ml',
    '.cf',
    '.ga',
    '.cn.com',
  };

  static const _dangerousExt = {
    '.apk',
    '.exe',
    '.bat',
    '.cmd',
    '.scr',
    '.js',
    '.vbs',
    '.msi',
    '.dmg',
  };

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(_key);
    level = switch (v) {
      'off' => SafeBrowsingLevel.off,
      'enhanced' => SafeBrowsingLevel.enhanced,
      _ => SafeBrowsingLevel.standard,
    };
  }

  Future<void> setLevel(SafeBrowsingLevel l) async {
    level = l;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, l.name);
  }

  String get label => switch (level) {
        SafeBrowsingLevel.off => 'Không bảo vệ',
        SafeBrowsingLevel.standard => 'Bảo vệ tiêu chuẩn',
        SafeBrowsingLevel.enhanced => 'Bảo vệ nâng cao',
      };

  /// null = cho qua; non-null = lý do chặn.
  String? blockReason(String url) {
    if (level == SafeBrowsingLevel.off) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final host = uri.host.toLowerCase();
    if (host.isEmpty) return null;

    for (final h in _badHosts) {
      if (host == h || host.endsWith('.$h')) {
        return 'Host nằm trong danh sách nguy hiểm cục bộ ($h)';
      }
    }

    // Phishing-ish patterns
    final path = url.toLowerCase();
    if (path.contains('login') &&
        (path.contains('paypal') ||
            path.contains('appleid') ||
            path.contains('account-google')) &&
        !host.endsWith('paypal.com') &&
        !host.endsWith('apple.com') &&
        !host.endsWith('google.com')) {
      return 'URL giống trang đăng nhập giả mạo';
    }

    if (level == SafeBrowsingLevel.enhanced) {
      // Bare IP
      if (RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(host)) {
        return 'Truy cập theo địa chỉ IP (chế độ nâng cao)';
      }
      for (final t in _riskyTlds) {
        if (host.endsWith(t)) {
          return 'TLD rủi ro cao ($t) ở chế độ nâng cao';
        }
      }
      final p = uri.path.toLowerCase();
      for (final e in _dangerousExt) {
        if (p.endsWith(e)) {
          return 'Tải file đuôi $e bị chặn ở chế độ nâng cao';
        }
      }
    }
    return null;
  }
}

final safeBrowsingService = SafeBrowsingService();
