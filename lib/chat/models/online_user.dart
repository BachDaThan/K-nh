class OnlineUser {
  final String uid;
  final String publicId;
  final String name;
  final String? photoUrl;
  final int lastSeen;
  final int nameOrdinal;
  final String rank;

  OnlineUser({
    required this.uid,
    required this.publicId,
    required this.name,
    this.photoUrl,
    required this.lastSeen,
    this.nameOrdinal = 1,
    this.rank = 'member',
  });

  factory OnlineUser.fromMap(String uid, Map data) => OnlineUser(
        uid: uid,
        publicId: '${data['publicId'] ?? _shortId(uid)}',
        name: '${data['name'] ?? 'User'}',
        photoUrl: data['photoUrl'] as String?,
        lastSeen: (data['lastSeen'] as num?)?.toInt() ?? 0,
        nameOrdinal: (data['nameOrdinal'] as num?)?.toInt() ?? 1,
        rank: '${data['rank'] ?? 'member'}',
      );

  static String _shortId(String uid) {
    if (uid.length < 6) return uid.toUpperCase();
    return uid.substring(0, 6).toUpperCase();
  }
}
