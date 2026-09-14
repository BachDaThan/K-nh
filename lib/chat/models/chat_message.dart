class ChatMessage {
  final String id;
  final String uid;
  final String publicId;
  final String name;
  final int nameOrdinal;
  final String rank;
  final String? photoUrl;
  final String text;
  final int ts;

  ChatMessage({
    required this.id,
    required this.uid,
    required this.publicId,
    required this.name,
    this.nameOrdinal = 1,
    this.rank = 'member',
    this.photoUrl,
    required this.text,
    required this.ts,
  });

  factory ChatMessage.fromMap(String id, Map data) => ChatMessage(
        id: id,
        uid: '${data['uid'] ?? ''}',
        publicId: '${data['publicId'] ?? ''}',
        name: '${data['name'] ?? 'Ẩn danh'}',
        nameOrdinal: (data['nameOrdinal'] as num?)?.toInt() ?? 1,
        rank: '${data['rank'] ?? 'member'}',
        photoUrl: data['photoUrl'] as String?,
        text: '${data['text'] ?? ''}',
        ts: (data['ts'] as num?)?.toInt() ?? 0,
      );
}
