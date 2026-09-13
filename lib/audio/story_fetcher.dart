import 'package:http/http.dart' as http;

class StoryChapter {
  final String title;
  final String content;
  final String url;
  final String? nextUrl;

  StoryChapter({
    required this.title,
    required this.content,
    required this.url,
    this.nextUrl,
  });
}

/// Lấy nội dung chương từ URL (HTML heuristic — không chạy plugin vBook zip).
class StoryFetcher {
  static Future<StoryChapter> fetch(String url) async {
    final uri = Uri.parse(url);
    final res = await http.get(uri, headers: {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml',
    }).timeout(const Duration(seconds: 25));
    if (res.statusCode < 200 || res.statusCode >= 400) {
      throw StateError('HTTP ${res.statusCode}');
    }
    final html = res.body;
    final title = _title(html);
    final content = _content(html);
    final next = _nextLink(html, uri);
    if (content.trim().length < 80) {
      throw StateError(
        'Không trích được nội dung (site chặn bot hoặc layout lạ). '
        'Thử mở trong trình duyệt Kính rồi bật TTS Reader.',
      );
    }
    return StoryChapter(
      title: title,
      content: content,
      url: url,
      nextUrl: next,
    );
  }

  static String _title(String html) {
    final m = RegExp(
      r'<title[^>]*>(.*?)</title>',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(html);
    if (m != null) return _strip(m.group(1)!);
    final h1 = RegExp(
      r'<h1[^>]*>(.*?)</h1>',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(html);
    if (h1 != null) return _strip(h1.group(1)!);
    return 'Chương';
  }

  static String _content(String html) {
    // Ưu tiên khối truyện phổ biến
    final patterns = [
      r'id=["'']chapter-c["''][^>]*>([\s\S]*?)</div>',
      r'id=["'']chapter-content["''][^>]*>([\s\S]*?)</div>',
      r'class=["''][^"'']*chapter-content[^"'']*["''][^>]*>([\s\S]*?)</div>',
      r'class=["''][^"'']*content[^"'']*["''][^>]*>([\s\S]*?)</div>',
      r'<article[^>]*>([\s\S]*?)</article>',
    ];
    for (final p in patterns) {
      final m = RegExp(p, caseSensitive: false).firstMatch(html);
      if (m != null) {
        final t = _strip(m.group(1)!);
        if (t.length > 120) return t;
      }
    }
    // Fallback: toàn bộ body text
    final body = RegExp(
      r'<body[^>]*>([\s\S]*?)</body>',
      caseSensitive: false,
    ).firstMatch(html);
    return _strip(body?.group(1) ?? html).substring(
      0,
      ((_strip(body?.group(1) ?? html).length).clamp(0, 50000)),
    );
  }

  static String? _nextLink(String html, Uri base) {
    final re = RegExp(
      r'''<a[^>]+href=["']([^"']+)["'][^>]*>([^<]{0,80})</a>''',
      caseSensitive: false,
    );
    final candidates = <String>[];
    for (final m in re.allMatches(html)) {
      final href = m.group(1)!.trim();
      final label = _strip(m.group(2)!).toLowerCase();
      if (label.contains('chương sau') ||
          label.contains('chuong sau') ||
          label.contains('next') ||
          label.contains('chap sau') ||
          label == 'sau' ||
          label.contains('tiếp') ||
          label.contains('tiep')) {
        candidates.add(href);
      }
    }
    if (candidates.isEmpty) return null;
    final href = candidates.first;
    final u = base.resolve(href);
    if (u.scheme != 'http' && u.scheme != 'https') return null;
    return u.toString();
  }

  static String _strip(String html) {
    var s = html
        .replaceAll(RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return s;
  }
}
