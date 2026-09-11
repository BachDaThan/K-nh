import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class CodeSnippet {
  final String id;
  String title;
  String language; // python | javascript
  String code;
  DateTime updatedAt;

  CodeSnippet({
    String? id,
    required this.title,
    required this.language,
    required this.code,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'language': language,
        'code': code,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CodeSnippet.fromJson(Map<String, dynamic> j) => CodeSnippet(
        id: j['id'] as String?,
        title: j['title'] as String? ?? 'Untitled',
        language: j['language'] as String? ?? 'python',
        code: j['code'] as String? ?? '',
        updatedAt:
            DateTime.tryParse(j['updatedAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class SnippetService {
  static const _key = 'kinh_snippets_v1';
  final List<CodeSnippet> _items = [];
  List<CodeSnippet> get items => List.unmodifiable(_items);

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    _items.clear();
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      for (final e in list) {
        _items.add(CodeSnippet.fromJson(Map<String, dynamic>.from(e as Map)));
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(_items.map((e) => e.toJson()).toList()));
  }

  Future<void> upsert(CodeSnippet s) async {
    final i = _items.indexWhere((e) => e.id == s.id);
    s.updatedAt = DateTime.now();
    if (i >= 0) {
      _items[i] = s;
    } else {
      _items.insert(0, s);
    }
    await _save();
  }

  Future<void> remove(String id) async {
    _items.removeWhere((e) => e.id == id);
    await _save();
  }
}
