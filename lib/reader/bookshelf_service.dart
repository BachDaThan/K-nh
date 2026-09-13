import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookEntry {
  final String id;
  final String title;
  final String path;
  int offset; // char offset for progress

  BookEntry({
    required this.id,
    required this.title,
    required this.path,
    this.offset = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'path': path,
        'offset': offset,
      };

  factory BookEntry.fromJson(Map<String, dynamic> j) => BookEntry(
        id: j['id'] as String,
        title: j['title'] as String,
        path: j['path'] as String,
        offset: j['offset'] as int? ?? 0,
      );
}

class BookshelfService {
  static const _key = 'kinh_bookshelf_v1';
  final List<BookEntry> books = [];

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    books.clear();
    if (raw == null) return;
    final list = jsonDecode(raw) as List;
    for (final e in list) {
      books.add(BookEntry.fromJson(e as Map<String, dynamic>));
    }
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _key,
      jsonEncode(books.map((b) => b.toJson()).toList()),
    );
  }

  Future<BookEntry> importTxtFile(String sourcePath, String name) async {
    final dir = await getApplicationDocumentsDirectory();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final dest = File('${dir.path}/books_$id.txt');
    await File(sourcePath).copy(dest.path);
    final entry = BookEntry(id: id, title: name, path: dest.path);
    books.add(entry);
    await _save();
    return entry;
  }

  Future<void> updateProgress(String id, int offset) async {
    final b = books.where((e) => e.id == id).firstOrNull;
    if (b == null) return;
    b.offset = offset;
    await _save();
  }

  Future<void> remove(String id) async {
    books.removeWhere((e) => e.id == id);
    await _save();
  }

  Future<String> readContent(BookEntry b) async {
    return File(b.path).readAsString();
  }
}

final bookshelfService = BookshelfService();
