import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../firebase_options.dart';
import '../models/chat_message.dart';
import '../models/online_user.dart';

/// Chat cộng đồng — Firebase RTDB + Google Sign-In.
/// Chỉ text/emoji; giới hạn tin để vừa gói Free Spark.
class ChatService extends ChangeNotifier {
  static const maxGlobal = 100;
  static const maxTopic = 80;
  static const maxPage = 60;
  static const maxDm = 50;
  static const pageTtlMs = 48 * 60 * 60 * 1000; // 48h

  static const topics = <String, String>{
    'gop-y': '#góp-ý-phản-hồi',
    'chia-se': '#chia-sẻ-link-hay',
    'tam-su': '#tâm-sự',
  };

  bool ready = false;
  String? initError;
  User? user;

  final _google = GoogleSignIn(scopes: ['email', 'profile']);
  DatabaseReference? _db;
  StreamSubscription? _connSub;
  StreamSubscription? _onlineSub;
  final List<OnlineUser> onlineUsers = [];

  bool get isSignedIn => user != null;

  Future<void> init() async {
    if (ready) return;
    try {
      final opts = DefaultFirebaseOptions.currentPlatform;
      if (opts.apiKey.startsWith('REPLACE_')) {
        initError =
            'Chưa cấu hình Firebase. Xem FIREBASE_CHAT_SETUP.md và điền lib/firebase_options.dart';
        notifyListeners();
        return;
      }
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: opts);
      }
      _db = FirebaseDatabase.instance.ref();
      FirebaseAuth.instance.authStateChanges().listen((u) {
        user = u;
        if (u != null) {
          _bindPresence();
        } else {
          _unbindPresence();
        }
        notifyListeners();
      });
      user = FirebaseAuth.instance.currentUser;
      if (user != null) await _bindPresence();
      ready = true;
      initError = null;
    } catch (e) {
      initError = '$e';
      ready = false;
    }
    notifyListeners();
  }

  Future<void> signIn() async {
    await init();
    if (initError != null) return;
    final gUser = await _google.signIn();
    if (gUser == null) return;
    final gAuth = await gUser.authentication;
    final cred = GoogleAuthProvider.credential(
      accessToken: gAuth.accessToken,
      idToken: gAuth.idToken,
    );
    await FirebaseAuth.instance.signInWithCredential(cred);
  }

  Future<void> signOut() async {
    await _setOffline();
    await FirebaseAuth.instance.signOut();
    await _google.signOut();
  }

  Future<void> _bindPresence() async {
    final u = user;
    final db = _db;
    if (u == null || db == null) return;
    final statusRef = db.child('presence/${u.uid}');
    final connectedRef = db.child('.info/connected');
    await _connSub?.cancel();
    _connSub = connectedRef.onValue.listen((event) async {
      final connected = event.snapshot.value == true;
      if (!connected) return;
      await statusRef.onDisconnect().set({
        'online': false,
        'name': u.displayName ?? 'User',
        'photoUrl': u.photoURL,
        'lastSeen': ServerValue.timestamp,
      });
      await statusRef.set({
        'online': true,
        'name': u.displayName ?? 'User',
        'photoUrl': u.photoURL,
        'lastSeen': ServerValue.timestamp,
      });
    });
    await _onlineSub?.cancel();
    _onlineSub = db.child('presence').onValue.listen((event) {
      onlineUsers.clear();
      final val = event.snapshot.value;
      if (val is Map) {
        val.forEach((k, v) {
          if (v is Map && v['online'] == true) {
            onlineUsers.add(OnlineUser.fromMap('$k', Map<String, dynamic>.from(v)));
          }
        });
        onlineUsers.sort((a, b) => a.name.compareTo(b.name));
      }
      notifyListeners();
    });
  }

  Future<void> _unbindPresence() async {
    await _connSub?.cancel();
    await _onlineSub?.cancel();
    onlineUsers.clear();
  }

  Future<void> _setOffline() async {
    final u = user;
    final db = _db;
    if (u == null || db == null) return;
    await db.child('presence/${u.uid}').set({
      'online': false,
      'name': u.displayName ?? 'User',
      'photoUrl': u.photoURL,
      'lastSeen': ServerValue.timestamp,
    });
  }

  /// roomKey examples:
  /// global | topic_gop-y | page_<hash> | dm_<uidA_uidB sorted>
  DatabaseReference _roomRef(String roomKey) =>
      _db!.child('rooms/$roomKey/messages');

  static String pageRoomKey(String url) {
    final u = Uri.tryParse(url);
    final norm = u == null
        ? url
        : '${u.scheme}://${u.host}${u.path}'.toLowerCase();
    final h = norm.hashCode.toRadixString(16);
    return 'page_$h';
  }

  static String dmRoomKey(String a, String b) {
    final ids = [a, b]..sort();
    return 'dm_${ids[0]}_${ids[1]}';
  }

  Stream<List<ChatMessage>> watchRoom(String roomKey, {int limit = 100}) {
    final q = _roomRef(roomKey).orderByChild('ts').limitToLast(limit);
    return q.onValue.map((event) {
      final list = <ChatMessage>[];
      final val = event.snapshot.value;
      if (val is Map) {
        val.forEach((k, v) {
          if (v is Map) {
            list.add(ChatMessage.fromMap('$k', Map<String, dynamic>.from(v)));
          }
        });
        list.sort((a, b) => a.ts.compareTo(b.ts));
      }
      return list;
    });
  }

  Future<void> send(String roomKey, String text, {int maxKeep = 100}) async {
    final u = user;
    if (u == null) throw StateError('Chưa đăng nhập');
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;
    if (cleaned.length > 500) {
      throw StateError('Tin nhắn tối đa 500 ký tự');
    }
    // Chỉ text + emoji (không URL dài spam quá mức — vẫn cho phép link ngắn)
    final ref = _roomRef(roomKey).push();
    await ref.set({
      'uid': u.uid,
      'name': u.displayName ?? 'User',
      'photoUrl': u.photoURL,
      'text': cleaned,
      'ts': ServerValue.timestamp,
    });
    await _trimRoom(roomKey, maxKeep);
  }

  Future<void> _trimRoom(String roomKey, int maxKeep) async {
    final snap = await _roomRef(roomKey).orderByChild('ts').get();
    final val = snap.value;
    if (val is! Map || val.length <= maxKeep) return;
    final entries = <MapEntry<String, int>>[];
    val.forEach((k, v) {
      if (v is Map) {
        entries.add(MapEntry('$k', (v['ts'] as num?)?.toInt() ?? 0));
      }
    });
    entries.sort((a, b) => a.value.compareTo(b.value));
    final toRemove = entries.length - maxKeep;
    for (var i = 0; i < toRemove; i++) {
      await _roomRef(roomKey).child(entries[i].key).remove();
    }
  }

  /// Xóa tin page-chat cũ hơn 48h (gọi khi mở phòng page).
  Future<void> purgeOldPageMessages(String roomKey) async {
    if (!roomKey.startsWith('page_')) return;
    final cutoff = DateTime.now().millisecondsSinceEpoch - pageTtlMs;
    final snap = await _roomRef(roomKey).orderByChild('ts').get();
    final val = snap.value;
    if (val is! Map) return;
    for (final e in val.entries) {
      if (e.value is Map) {
        final ts = (e.value['ts'] as num?)?.toInt() ?? 0;
        if (ts > 0 && ts < cutoff) {
          await _roomRef(roomKey).child('${e.key}').remove();
        }
      }
    }
  }
}

final chatService = ChatService();
