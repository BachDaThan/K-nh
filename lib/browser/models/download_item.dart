import 'package:uuid/uuid.dart';

enum DownloadStatus { queued, downloading, paused, completed, failed, cancelled }

/// Một mục trong Download Manager.
class DownloadItem {
  final String id;
  final String url;
  final String fileName;
  final String? savePath;
  DownloadStatus status;
  int receivedBytes;
  int totalBytes; // -1 nếu unknown
  DateTime createdAt;
  String? error;

  DownloadItem({
    String? id,
    required this.url,
    required this.fileName,
    this.savePath,
    this.status = DownloadStatus.queued,
    this.receivedBytes = 0,
    this.totalBytes = -1,
    DateTime? createdAt,
    this.error,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  double get progress {
    if (totalBytes <= 0) return 0.0;
    return (receivedBytes / totalBytes).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'fileName': fileName,
        'savePath': savePath,
        'status': status.name,
        'receivedBytes': receivedBytes,
        'totalBytes': totalBytes,
        'createdAt': createdAt.toIso8601String(),
        'error': error,
      };

  factory DownloadItem.fromJson(Map<String, dynamic> json) => DownloadItem(
        id: json['id'] as String,
        url: json['url'] as String,
        fileName: json['fileName'] as String,
        savePath: json['savePath'] as String?,
        status: DownloadStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => DownloadStatus.queued,
        ),
        receivedBytes: json['receivedBytes'] as int? ?? 0,
        totalBytes: json['totalBytes'] as int? ?? -1,
        createdAt: DateTime.parse(json['createdAt'] as String),
        error: json['error'] as String?,
      );
}
