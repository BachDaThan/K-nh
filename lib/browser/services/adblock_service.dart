import 'package:shared_preferences/shared_preferences.dart';

class AdblockService {
  static const _key = 'kinh_adblock_enabled';
  bool enabled = true;

  static const blockedHosts = <String>{
    'doubleclick.net',
    'googlesyndication.com',
    'googleadservices.com',
    'pagead2.googlesyndication.com',
    'adservice.google.com',
    'adnxs.com',
    'adsrvr.org',
    'amazon-adsystem.com',
    'advertising.com',
    'adform.net',
    'ads-twitter.com',
    'scorecardresearch.com',
    'outbrain.com',
    'taboola.com',
    'criteo.com',
    'criteo.net',
    'pubmatic.com',
    'rubiconproject.com',
    'openx.net',
    'moatads.com',
    'googletagservices.com',
  };

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    enabled = p.getBool(_key) ?? true;
  }

  Future<void> setEnabled(bool v) async {
    enabled = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, v);
  }

  bool shouldBlock(String url) {
    if (!enabled) return false;
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    if (host.isEmpty) return false;
    // never block main search engines
    const allow = {
      'www.google.com',
      'google.com',
      'duckduckgo.com',
      'www.bing.com',
      'search.brave.com',
      'www.startpage.com',
    };
    if (allow.contains(host)) return false;
    for (final b in blockedHosts) {
      if (host == b || host.endsWith('.$b')) return true;
    }
    return false;
  }
}

final adblockService = AdblockService();
