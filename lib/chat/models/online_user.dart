class OnlineUser {
  final String uid;
  final String name;
  final String? photoUrl;
  final int lastSeen;

  OnlineUser({
    required this.uid,
    required this.name,
    this.photoUrl,
    required this.lastSeen,
  });

  factory OnlineUser.fromMap(String uid, Map data) => OnlineUser(
        uid: uid,
        name: '${data['name'] ?? 'User'}',
        photoUrl: data['photoUrl'] as String?,
        lastSeen: (data['lastSeen'] as num?)?.toInt() ?? 0,
      );
}
