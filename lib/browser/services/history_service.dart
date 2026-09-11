import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_entry.dart';

class HistoryService {
  static const _key = 'kinh_history_v1';
  static const _maxEntries = 500;

  final List<HistoryEntry> _items = [];
  List<HistoryEntry> get items => List.unmodifiable(_items);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    _items.clear();
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      for (final e in list) {
        _items.add(HistoryEntry.fromJson(Map<String, dynamic>.from(e as Map)));
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_items.map((e) => e.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  /// Ghi lịch sử (bỏ qua about:blank / empty). Không gọi khi incognito.
  Future<void> add({
    required String title,
    required String url,
  }) async {
    if (url.isEmpty || url == 'about:blank') return;
    final domain = HistoryEntry.domainOf(url);
    // Gộp visit liên tiếp cùng URL
    if (_items.isNotEmpty && _items.first.url == url) {
      _items[0] = HistoryEntry(
        id: _items.first.id,
        title: title.isNotEmpty ? title : _items.first.title,
        url: url,
        domain: domain,
        visitedAt: DateTime.now(),
      );
    } else {
      _items.insert(
        0,
        HistoryEntry(
          title: title.isEmpty ? domain : title,
          url: url,
          domain: domain,
        ),
      );
    }
    while (_items.length > _maxEntries) {
      _items.removeLast();
    }
    await _persist();
  }

  Future<void> remove(String id) async {
    _items.removeWhere((e) => e.id == id);
    await _persist();
  }

  Future<void> clearAll() async {
    _items.clear();
    await _persist();
  }

  Future<void> clearDomain(String domain) async {
    final d = domain.replaceFirst(RegExp(r'^www\.'), '');
    _items.removeWhere((e) => e.domain == d);
    await _persist();
  }

  List<String> get domains {
    final set = <String>{};
    for (final e in _items) {
      if (e.domain.isNotEmpty) set.add(e.domain);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<HistoryEntry> byDomain(String domain) {
    final d = domain.replaceFirst(RegExp(r'^www\.'), '');
    return _items.where((e) => e.domain == d).toList();
  }

  List<HistoryEntry> search(String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) return items;
    return _items
        .where((e) =>
            e.title.toLowerCase().contains(query) ||
            e.url.toLowerCase().contains(query) ||
            e.domain.toLowerCase().contains(query))
        .toList();
  }
}
