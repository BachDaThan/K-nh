import 'package:shared_preferences/shared_preferences.dart';

class SearchEngine {
  final String id;
  final String name;
  final String Function(String query) buildUrl;

  const SearchEngine({
    required this.id,
    required this.name,
    required this.buildUrl,
  });
}

/// Máy tìm kiếm mặc định cho Omnibox (khi gõ từ khóa, không phải URL).
class SearchEngineService {
  static const _key = 'kinh_search_engine_id';

  static final engines = <SearchEngine>[
    SearchEngine(
      id: 'google',
      name: 'Google',
      buildUrl: (q) =>
          'https://www.google.com/search?q=${Uri.encodeComponent(q)}',
    ),
    SearchEngine(
      id: 'ddg',
      name: 'DuckDuckGo',
      buildUrl: (q) =>
          'https://duckduckgo.com/?q=${Uri.encodeComponent(q)}',
    ),
    SearchEngine(
      id: 'bing',
      name: 'Bing',
      buildUrl: (q) =>
          'https://www.bing.com/search?q=${Uri.encodeComponent(q)}',
    ),
    SearchEngine(
      id: 'brave',
      name: 'Brave Search',
      buildUrl: (q) =>
          'https://search.brave.com/search?q=${Uri.encodeComponent(q)}',
    ),
    SearchEngine(
      id: 'startpage',
      name: 'Startpage',
      buildUrl: (q) =>
          'https://www.startpage.com/sp/search?query=${Uri.encodeComponent(q)}',
    ),
  ];

  String _id = 'google';
  bool _loaded = false;
  String get currentId => _id;
  SearchEngine get current =>
      engines.firstWhere((e) => e.id == _id, orElse: () => engines.first);

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _id = p.getString(_key) ?? 'google';
    _loaded = true;
  }

  Future<void> setEngine(String id) async {
    if (!engines.any((e) => e.id == id)) return;
    _id = id;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, id);
  }

  String searchUrl(String query) {
    // load() should be awaited at app start; if not, still use in-memory default
    return current.buildUrl(query);
  }
}

/// Singleton để engine đọc khi normalize query.
final searchEngineService = SearchEngineService();
