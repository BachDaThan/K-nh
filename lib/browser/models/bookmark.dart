import 'package:uuid/uuid.dart';

/// Một bookmark.
class Bookmark {
  final String id;
  final String title;
  final String url;
  final DateTime createdAt;
  final String? folder; // null = root / Bookmark Bar

  Bookmark({
    String? id,
    required this.title,
    required this.url,
    DateTime? createdAt,
    this.folder,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'url': url,
        'createdAt': createdAt.toIso8601String(),
        'folder': folder,
      };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
        id: json['id'] as String,
        title: json['title'] as String,
        url: json['url'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        folder: json['folder'] as String?,
      );
}
