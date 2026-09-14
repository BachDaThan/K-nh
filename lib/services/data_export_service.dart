import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../browser/services/bookmark_service.dart';
import '../browser/services/history_service.dart';

class DataExportService {
  Future<Directory> _dir() async {
    final d = await getApplicationDocumentsDirectory();
    final out = Directory('${d.path}/kinh_export');
    if (!await out.exists()) await out.create(recursive: true);
    return out;
  }

  /// Netscape-ish HTML bookmarks — import được Chrome/Firefox.
  Future<File> exportBookmarksHtml(BookmarkService bookmarks) async {
    await bookmarks.load();
    final buf = StringBuffer()
      ..writeln('<!DOCTYPE NETSCAPE-Bookmark-file-1>')
      ..writeln('<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">')
      ..writeln('<title>Kính Bookmarks</title>')
      ..writeln('<h1>Kính Bookmarks</h1><dl><p>');
    for (final b in bookmarks.items) {
      final t = _esc(b.title);
      final u = _esc(b.url);
      final add = (b.createdAt.millisecondsSinceEpoch ~/ 1000);
      buf.writeln(
        '    <dt><a href="$u" add_date="$add">${t.isEmpty ? u : t}</a>',
      );
    }
    buf.writeln('</dl><p>');
    final f = File('${(await _dir()).path}/kinh_bookmarks.html');
    await f.writeAsString(buf.toString(), encoding: utf8);
    return f;
  }

  Future<File> exportHistoryCsv(HistoryService history) async {
    await history.load();
    final buf = StringBuffer('visited_at,domain,title,url\n');
    for (final e in history.items) {
      buf.writeln(
        '${e.visitedAt.toIso8601String()},${_csv(e.domain)},${_csv(e.title)},${_csv(e.url)}',
      );
    }
    final f = File('${(await _dir()).path}/kinh_history.csv');
    await f.writeAsString(buf.toString(), encoding: utf8);
    return f;
  }

  Future<File> exportNotesMarkdown() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList('kinh_notes_v1') ?? [];
    final buf = StringBuffer('# Ghi chú Kính\n\n');
    for (final e in raw) {
      final parts = e.split('\u001e');
      if (parts.length >= 4) {
        final title = parts[1];
        final body = parts[2];
        final at = parts[3];
        buf
          ..writeln('## ${title.isEmpty ? "(không tiêu đề)" : title}')
          ..writeln()
          ..writeln(body)
          ..writeln()
          ..writeln('_${at}_')
          ..writeln()
          ..writeln('---')
          ..writeln();
      }
    }
    final f = File('${(await _dir()).path}/kinh_notes.md');
    await f.writeAsString(buf.toString(), encoding: utf8);
    return f;
  }

  String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  String _csv(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }
}

final dataExportService = DataExportService();
