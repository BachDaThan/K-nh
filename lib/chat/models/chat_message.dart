class ChatMessage {
  final String id;
  final String uid;
  final String name;
  final String? photoUrl;
  final String text;
  final int ts;

  ChatMessage({
    required this.id,
    required this.uid,
    required this.name,
    this.photoUrl,
    required this.text,
    required this.ts,
  });

  factory ChatMessage.fromMap(String id, Map data) => ChatMessage(
        id: id,
        uid: '${data['uid'] ?? ''}',
        name: '${data['name'] ?? 'Ẩn danh'}',
        photoUrl: data['photoUrl'] as String?,
        text: '${data['text'] ?? ''}',
        ts: (data['ts'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'photoUrl': photoUrl,
        'text': text,
        'ts': ts,
      };
}
