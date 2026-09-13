import 'package:shared_preferences/shared_preferences.dart';

class SearchEngine {
  final String id;
  final String name;
  final String homeUrl;
  final String Function(String query) buildUrl;

  const SearchEngine({
    required this.id,
    required this.name,
    required this.homeUrl,
    required this.buildUrl,
  });
}

class SearchEngineService {
  static const _key = 'kinh_search_engine_id';

  static final engines = <SearchEngine>[
    SearchEngine(
      id: 'google',
      name: 'Google',
      homeUrl: 'https://www.google.com/',
      buildUrl: (q) =>
          'https://www.google.com/search?q=${Uri.encodeComponent(q)}',
    ),
    SearchEngine(
      id: 'ddg',
      name: 'DuckDuckGo',
      homeUrl: 'https://duckduckgo.com/',
      buildUrl: (q) =>
          'https://duckduckgo.com/?q=${Uri.encodeComponent(q)}',
    ),
    SearchEngine(
      id: 'bing',
      name: 'Bing',
      homeUrl: 'https://www.bing.com/',
      buildUrl: (q) =>
          'https://www.bing.com/search?q=${Uri.encodeComponent(q)}',
    ),
    SearchEngine(
      id: 'brave',
      name: 'Brave Search',
      homeUrl: 'https://search.brave.com/',
      buildUrl: (q) =>
          'https://search.brave.com/search?q=${Uri.encodeComponent(q)}',
    ),
    SearchEngine(
      id: 'startpage',
      name: 'Startpage',
      homeUrl: 'https://www.startpage.com/',
      buildUrl: (q) =>
          'https://www.startpage.com/sp/search?query=${Uri.encodeComponent(q)}',
    ),
  ];

  String _id = 'google';
  void Function(SearchEngine engine)? onEngineChanged;

  String get currentId => _id;
  SearchEngine get current =>
      engines.firstWhere((e) => e.id == _id, orElse: () => engines.first);

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _id = p.getString(_key) ?? 'google';
  }

  Future<void> setEngine(String id) async {
    if (!engines.any((e) => e.id == id)) return;
    _id = id;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, id);
    onEngineChanged?.call(current);
  }

  String searchUrl(String query) => current.buildUrl(query);
}

final searchEngineService = SearchEngineService();
