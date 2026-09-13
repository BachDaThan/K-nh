import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_edition.dart';
import '../../addons/addon_service.dart';
import 'web_cosmetics_service.dart';

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
    'media.net',
    'adsafeprotected.com',
    'yieldmo.com',
    'casalemedia.com',
    '2mdn.net',
  };

  static const advancedExtraHosts = <String>{
    'facebook.com/tr',
    'connect.facebook.net',
    'hotjar.com',
    'clarity.ms',
    'quantserve.com',
    'exelator.com',
    'bluekai.com',
    'bidswitch.net',
    'sharethrough.com',
    'liadm.com',
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
    if (webCosmeticsService.advancedAdblock) {
      for (final b in advancedExtraHosts) {
        if (host == b || host.endsWith('.$b') || url.contains(b)) return true;
      }
    }
    if (AppEdition.isPlus && addonService.shouldBlockHost(url)) return true;
    return false;
  }
}


final adblockService = AdblockService();
