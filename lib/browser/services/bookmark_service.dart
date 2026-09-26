import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bookmark.dart';

class BookmarkService {
  static const _key = 'bookmarks_v1';
  final List<Bookmark> _items = [];

  List<Bookmark> get items => List.unmodifiable(_items);

  List<Bookmark> get barItems =>
      _items.where((b) => b.folder == null || b.folder == 'bar').toList();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    _items.clear();
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final e in decoded) {
            if (e is! Map) continue;
            try {
              _items.add(Bookmark.fromJson(Map<String, dynamic>.from(e)));
            } catch (_) {}
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(_items.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> add(Bookmark bookmark) async {
    _items.removeWhere((b) => b.url == bookmark.url);
    _items.insert(0, bookmark);
    await _save();
  }

  Future<void> remove(String id) async {
    _items.removeWhere((b) => b.id == id);
    await _save();
  }

  bool containsUrl(String url) => _items.any((b) => b.url == url);
}
