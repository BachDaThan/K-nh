import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// "Tiện ích giả" hướng A — không phải extension Firefox/Chrome.
/// User CSS + JS inject + danh sách host chặn tải thêm.
class AddonService {
  static const _kCss = 'kinh_plus_user_css';
  static const _kJs = 'kinh_plus_user_js';
  static const _kHosts = 'kinh_plus_extra_hosts';
  static const _kEnabled = 'kinh_plus_addons_on';

  bool enabled = true;
  String userCss = '';
  String userJs = '';
  List<String> extraHosts = [];

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    enabled = p.getBool(_kEnabled) ?? true;
    userCss = p.getString(_kCss) ?? '';
    userJs = p.getString(_kJs) ?? '';
    extraHosts = p.getStringList(_kHosts) ?? [];
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kEnabled, enabled);
    await p.setString(_kCss, userCss);
    await p.setString(_kJs, userJs);
    await p.setStringList(_kHosts, extraHosts);
  }

  bool shouldBlockHost(String url) {
    if (!enabled) return false;
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    if (host.isEmpty) return false;
    for (final h in extraHosts) {
      final x = h.trim().toLowerCase();
      if (x.isEmpty || x.startsWith('!')) continue;
      if (host == x || host.endsWith('.$x')) return true;
    }
    return false;
  }

  String injectJs() {
    if (!enabled) return '';
    final buf = StringBuffer();
    if (userCss.trim().isNotEmpty) {
      final css = userCss
          .replaceAll('\\', '\\\\')
          .replaceAll('`', '\\`')
          .replaceAll(r'$', r'\$');
      buf.writeln(
        "var _kcss=document.getElementById('kinh-plus-css');"
        "if(_kcss)_kcss.remove();"
        "var s=document.createElement('style');s.id='kinh-plus-css';"
        "s.textContent=`$css`;document.documentElement.appendChild(s);",
      );
    }
    if (userJs.trim().isNotEmpty) {
      buf.writeln('(function(){ try {');
      buf.writeln(userJs);
      buf.writeln('} catch(e) {} })();');
    }
    return buf.toString();
  }

  /// Tải list host (mỗi dòng một domain). Mặc định list nhỏ EasyList-like.
  Future<int> importHostList(String url) async {
    final res = await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 20),
        );
    if (res.statusCode != 200) {
      throw StateError('Tải list ${res.statusCode}');
    }
    final hosts = <String>[];
    for (final line in res.body.split('\n')) {
      var s = line.trim();
      if (s.isEmpty || s.startsWith('!') || s.startsWith('[')) continue;
      if (s.startsWith('||')) s = s.substring(2);
      s = s.split('^').first.split('/').first.split('*').first;
      s = s.replaceAll(RegExp(r'[^a-zA-Z0-9.\-]'), '');
      if (s.contains('.') && s.length < 80) hosts.add(s.toLowerCase());
      if (hosts.length >= 400) break;
    }
    extraHosts = hosts.toSet().toList()..sort();
    await save();
    return extraHosts.length;
  }
}

final addonService = AddonService();
