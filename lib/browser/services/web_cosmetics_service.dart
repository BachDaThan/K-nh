import 'package:shared_preferences/shared_preferences.dart';

class WebCosmeticsService {
  static const _kDark = 'kinh_web_dark_mode';
  static const _kAdvAd = 'kinh_adblock_advanced';

  bool webDarkMode = false;
  bool advancedAdblock = false;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    webDarkMode = p.getBool(_kDark) ?? false;
    advancedAdblock = p.getBool(_kAdvAd) ?? false;
  }

  Future<void> setWebDarkMode(bool v) async {
    webDarkMode = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kDark, v);
  }

  Future<void> setAdvancedAdblock(bool v) async {
    advancedAdblock = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kAdvAd, v);
  }

  /// CSS ẩn quảng cáo phổ biến (cosmetic filter nhẹ).
  String get advancedHideCss => r'''
iframe[src*="doubleclick"], iframe[src*="googlesyndication"],
iframe[id*="google_ads"], div[id*="google_ads"], div[class*="ad-container"],
div[class*="adsbox"], div[id^="ad-"], aside[class*="ad"],
div[data-ad], .advertisement, .adsbygoogle { display: none !important; }
''';

  String get darkModeCss => r'''
html { background: #121212 !important; }
body, div, section, article, main, p, span, li, td, th {
  background-color: transparent !important;
  color: #e0e0e0 !important;
  border-color: #333 !important;
}
a { color: #8ab4f8 !important; }
img, video { opacity: 0.92; }
''';

  String injectScript({required bool dark, required bool advAd}) {
    final parts = <String>[];
    if (advAd) {
      parts.add(
        "var s1=document.createElement('style');s1.id='kinh-adv-ad';s1.textContent=`$advancedHideCss`;document.documentElement.appendChild(s1);",
      );
    }
    if (dark) {
      parts.add(
        "var s2=document.createElement('style');s2.id='kinh-dark';s2.textContent=`$darkModeCss`;document.documentElement.appendChild(s2);",
      );
    }
    if (parts.isEmpty) {
      return "['kinh-adv-ad','kinh-dark'].forEach(function(id){var e=document.getElementById(id);if(e)e.remove();});";
    }
    return parts.join('\n');
  }
}

final webCosmeticsService = WebCosmeticsService();
