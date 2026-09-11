import 'package:uuid/uuid.dart';

enum ActivityKind {
  navigation,
  pageFinished,
  error,
  download,
  cookieClear,
  cacheClear,
  historyClear,
  incognitoStart,
  incognitoEnd,
  settings,
  other,
}

class ActivityEvent {
  final String id;
  final ActivityKind kind;
  final String message;
  final String? url;
  final String? domain;
  final DateTime at;
  final bool ephemeral; // true = chỉ RAM (incognito)

  ActivityEvent({
    String? id,
    required this.kind,
    required this.message,
    this.url,
    this.domain,
    DateTime? at,
    this.ephemeral = false,
  })  : id = id ?? const Uuid().v4(),
        at = at ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'message': message,
        'url': url,
        'domain': domain,
        'at': at.toIso8601String(),
      };

  factory ActivityEvent.fromJson(Map<String, dynamic> j) => ActivityEvent(
        id: j['id'] as String?,
        kind: ActivityKind.values.firstWhere(
          (e) => e.name == j['kind'],
          orElse: () => ActivityKind.other,
        ),
        message: j['message'] as String? ?? '',
        url: j['url'] as String?,
        domain: j['domain'] as String?,
        at: DateTime.tryParse(j['at'] as String? ?? '') ?? DateTime.now(),
      );
}
