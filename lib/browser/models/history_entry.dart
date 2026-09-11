import 'package:uuid/uuid.dart';

class HistoryEntry {
  final String id;
  final String title;
  final String url;
  final String domain;
  final DateTime visitedAt;

  HistoryEntry({
    String? id,
    required this.title,
    required this.url,
    required this.domain,
    DateTime? visitedAt,
  })  : id = id ?? const Uuid().v4(),
        visitedAt = visitedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'url': url,
        'domain': domain,
        'visitedAt': visitedAt.toIso8601String(),
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
        id: j['id'] as String?,
        title: j['title'] as String? ?? '',
        url: j['url'] as String? ?? '',
        domain: j['domain'] as String? ?? '',
        visitedAt: DateTime.tryParse(j['visitedAt'] as String? ?? '') ??
            DateTime.now(),
      );

  static String domainOf(String url) {
    try {
      final u = Uri.parse(url.contains('://') ? url : 'https://$url');
      return u.host.replaceFirst(RegExp(r'^www\.'), '');
    } catch (_) {
      return url;
    }
  }
}
