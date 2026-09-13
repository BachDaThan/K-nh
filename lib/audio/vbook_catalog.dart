import 'dart:convert';
import 'package:http/http.dart' as http;

class VbookPlugin {
  final String name;
  final String source;
  final String description;
  final String? icon;

  VbookPlugin({
    required this.name,
    required this.source,
    required this.description,
    this.icon,
  });
}

class VbookCatalog {
  static const catalogUrl = 'https://www.vbookext.me/api/plugin.json';

  static Future<List<VbookPlugin>> load() async {
    final res = await http.get(Uri.parse(catalogUrl)).timeout(
          const Duration(seconds: 20),
        );
    if (res.statusCode != 200) {
      throw StateError('Catalog HTTP ${res.statusCode}');
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final data = j['data'] as List<dynamic>? ?? [];
    final out = <VbookPlugin>[];
    for (final e in data) {
      if (e is! Map) continue;
      final source = '${e['source'] ?? ''}';
      if (source.isEmpty) continue;
      out.add(VbookPlugin(
        name: '${e['name'] ?? 'Plugin'}',
        source: source,
        description: '${e['description'] ?? ''}',
        icon: e['icon'] as String?,
      ));
    }
    return out;
  }
}
