import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../firebase_options.dart';
import '../models/chat_message.dart';
import '../models/online_user.dart';

class ChatService extends ChangeNotifier {
  static const maxGlobal = 100;
  static const maxTopic = 80;
  static const maxPage = 60;
  static const maxDm = 50;
  /// Phòng URL / topic: không tin mới trong 30 ngày → xóa.
  static const inactiveTtlMs = 30 * 24 * 60 * 60 * 1000;
  static const maxMsgPerSec = 2;
  static const maxMsgPerMin = 20;

  static const topics = <String, String>{
    'gop-y': '#góp-ý-phản-hồi',
    'chia-se': '#chia-sẻ-link-hay',
    'tam-su': '#tâm-sự',
  };

  bool ready = false;
  bool signingIn = false;
  String? initError;
  String? lastAuthError;
  User? user;
  String? publicId;
  String displayName = '';
  int nameOrdinal = 1;
  String rank = 'member';
  /// Danh hiệu tên đã từng claim: name -> ordinal
  Map<String, int> nameTitles = {};

  final _google = GoogleSignIn(scopes: ['email', 'profile']);
  DatabaseReference? _db;
  StreamSubscription? _connSub;
  StreamSubscription? _onlineSub;
  final List<OnlineUser> onlineUsers = [];
  final List<int> _sendTimestamps = [];
  String? _deviceId;

  bool get isSignedIn => user != null;

  Future<void> init() async {
    if (ready && initError == null) return;
    try {
      final opts = DefaultFirebaseOptions.currentPlatform;
      if (opts.apiKey.contains('REPLACE') || opts.projectId.contains('REPLACE')) {
        initError =
            'Chưa cấu hình Firebase (apiKey/projectId). Xem FIREBASE_CHAT_SETUP.md';
        notifyListeners();
        return;
      }
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: opts);
      }
      _db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: opts.databaseURL,
      ).ref();
      await _ensureDeviceId();
      FirebaseAuth.instance.authStateChanges().listen((u) async {
        user = u;
        if (u != null) {
          await _onSignedIn(u);
        } else {
          publicId = null;
          displayName = '';
          nameOrdinal = 1;
          rank = 'member';
          nameTitles = {};
          await _unbindPresence();
        }
        notifyListeners();
      });
      user = FirebaseAuth.instance.currentUser;
      if (user != null) await _onSignedIn(user!);
      ready = true;
      initError = null;
    } catch (e, st) {
      debugPrint('ChatService.init: $e\n$st');
      initError = 'Firebase init: $e';
      ready = false;
    }
    notifyListeners();
  }

  Future<void> _ensureDeviceId() async {
    final p = await SharedPreferences.getInstance();
    var id = p.getString('kinh_device_id');
    if (id == null || id.isEmpty) {
      id = List.generate(12, (_) => Random().nextInt(16).toRadixString(16))
          .join()
          .toUpperCase();
      await p.setString('kinh_device_id', id);
    }
    _deviceId = id;
  }

  static String shortPublicId(String uid) {
    // ID công khai ổn định, dễ gõ tìm (6 ký tự)
    var h = 0;
    for (final c in uid.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h.toRadixString(36).toUpperCase().padLeft(6, '0').substring(0, 6);
  }

  Future<void> _onSignedIn(User u) async {
    publicId = shortPublicId(u.uid);
    displayName = u.displayName?.trim().isNotEmpty == true
        ? u.displayName!.trim()
        : (u.email?.split('@').first ?? 'User');
    final profile = await _db!.child('users/${u.uid}').get();
    if (profile.value is Map) {
      final m = Map<String, dynamic>.from(profile.value as Map);
      rank = '${m['rank'] ?? 'member'}';
      if (m['nameTitles'] is Map) {
        nameTitles = Map<String, int>.from(
          (m['nameTitles'] as Map).map(
            (k, v) => MapEntry('$k', (v as num).toInt()),
          ),
        );
      }
      if (m['displayName'] is String && (m['displayName'] as String).isNotEmpty) {
        displayName = m['displayName'] as String;
      }
      nameOrdinal = (m['nameOrdinal'] as num?)?.toInt() ??
          nameTitles[displayName.toLowerCase()] ??
          1;
    }
    await _registerName(displayName);
    await _db!.child('users/${u.uid}').update({
      'publicId': publicId,
      'displayName': displayName,
      'nameOrdinal': nameOrdinal,
      'rank': rank,
      'photoUrl': u.photoURL,
      'email': u.email,
      'updatedAt': ServerValue.timestamp,
    });
    // Index publicId → uid để tìm
    await _db!.child('publicIds/$publicId').set(u.uid);
    await _bindPresence();
  }

  /// Claim thứ tự tên hiển thị (T lần đầu = #1).
  Future<int> _registerName(String name) async {
    final key = name.trim().toLowerCase();
    if (key.isEmpty || user == null) return 1;
    if (nameTitles.containsKey(key)) {
      nameOrdinal = nameTitles[key]!;
      return nameOrdinal;
    }
    final ref = _db!.child('nameRegistry/$key');
    final snap = await ref.get();
    int ordinal;
    if (snap.value is Map) {
      final next = ((snap.value as Map)['next'] as num?)?.toInt() ?? 1;
      ordinal = next;
      await ref.update({'next': next + 1});
    } else {
      ordinal = 1;
      await ref.set({'next': 2});
    }
    nameTitles[key] = ordinal;
    nameOrdinal = ordinal;
    await _db!.child('users/${user!.uid}/nameTitles/$key').set(ordinal);
    await _db!.child('users/${user!.uid}').update({
      'displayName': name,
      'nameOrdinal': ordinal,
    });
    return ordinal;
  }

  Future<void> setDisplayName(String name) async {
    final n = name.trim();
    if (n.isEmpty || n.length > 24) {
      throw StateError('Tên 1–24 ký tự');
    }
    displayName = n;
    await _registerName(n);
    notifyListeners();
    if (user != null) await _bindPresence();
  }

  Future<void> signIn() async {
    lastAuthError = null;
    signingIn = true;
    notifyListeners();
    try {
      await init();
      if (initError != null) {
        lastAuthError = initError;
        return;
      }
      // Thử silent trước
      GoogleSignInAccount? gUser = await _google.signInSilently();
      gUser ??= await _google.signIn();
      if (gUser == null) {
        lastAuthError = 'Bạn đã hủy đăng nhập Google';
        return;
      }
      final gAuth = await gUser.authentication;
      if (gAuth.idToken == null && gAuth.accessToken == null) {
        lastAuthError =
            'Google không trả token. Kiểm tra SHA-1 keystore trong Firebase Console.';
        return;
      }
      final cred = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(cred);
      lastAuthError = null;
    } on FirebaseAuthException catch (e) {
      lastAuthError = 'Auth ${e.code}: ${e.message}';
      debugPrint(lastAuthError);
    } catch (e) {
      lastAuthError = '$e';
      debugPrint('signIn error: $e');
    } finally {
      signingIn = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _setOffline();
    await FirebaseAuth.instance.signOut();
    try {
      await _google.signOut();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _bindPresence() async {
    final u = user;
    final db = _db;
    if (u == null || db == null) return;
    final statusRef = db.child('presence/${u.uid}');
    final payload = {
      'online': true,
      'publicId': publicId,
      'name': displayName,
      'nameOrdinal': nameOrdinal,
      'rank': rank,
      'photoUrl': u.photoURL,
      'lastSeen': ServerValue.timestamp,
    };
    final connectedRef = db.child('.info/connected');
    await _connSub?.cancel();
    _connSub = connectedRef.onValue.listen((event) async {
      if (event.snapshot.value != true) return;
      await statusRef.onDisconnect().set({
        ...payload,
        'online': false,
        'lastSeen': ServerValue.timestamp,
      });
      await statusRef.set(payload);
    });
    await _onlineSub?.cancel();
    _onlineSub = db.child('presence').onValue.listen((event) {
      onlineUsers.clear();
      final val = event.snapshot.value;
      if (val is Map) {
        val.forEach((k, v) {
          if (v is Map && v['online'] == true) {
            onlineUsers
                .add(OnlineUser.fromMap('$k', Map<String, dynamic>.from(v)));
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
    if (u == null || _db == null) return;
    await _db!.child('presence/${u.uid}').update({
      'online': false,
      'lastSeen': ServerValue.timestamp,
    });
  }

  DatabaseReference _roomRef(String roomKey) =>
      _db!.child('rooms/$roomKey/messages');

  DatabaseReference _metaRef(String roomKey) =>
      _db!.child('rooms/$roomKey/meta');

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

  bool _rateLimitOk() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _sendTimestamps.removeWhere((t) => now - t > 60000);
    final lastSec = _sendTimestamps.where((t) => now - t < 1000).length;
    if (lastSec >= maxMsgPerSec) return false;
    if (_sendTimestamps.length >= maxMsgPerMin) return false;
    _sendTimestamps.add(now);
    return true;
  }

  Future<void> send(String roomKey, String text, {int maxKeep = 100}) async {
    final u = user;
    if (u == null) throw StateError('Chưa đăng nhập');
    if (!_rateLimitOk()) {
      throw StateError('Gửi quá nhanh — tối đa $maxMsgPerSec tin/giây, $maxMsgPerMin/phút');
    }
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;
    if (cleaned.length > 500) throw StateError('Tối đa 500 ký tự');

    final ref = _roomRef(roomKey).push();
    await ref.set({
      'uid': u.uid,
      'publicId': publicId,
      'name': displayName,
      'nameOrdinal': nameOrdinal,
      'rank': rank,
      'photoUrl': u.photoURL,
      'text': cleaned,
      'deviceId': _deviceId,
      'ts': ServerValue.timestamp,
    });
    await _metaRef(roomKey).update({
      'lastMessageAt': ServerValue.timestamp,
      'type': roomKey.startsWith('page_')
          ? 'page'
          : roomKey.startsWith('dm_')
              ? 'dm'
              : roomKey.startsWith('topic_')
                  ? 'topic'
                  : 'global',
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

  /// Xóa phòng không hoạt động 30 ngày (page/topic). Gọi khi mở hub.
  Future<int> purgeInactiveRooms() async {
    if (_db == null) return 0;
    final snap = await _db!.child('rooms').get();
    final val = snap.value;
    if (val is! Map) return 0;
    final cutoff = DateTime.now().millisecondsSinceEpoch - inactiveTtlMs;
    var removed = 0;
    for (final e in val.entries) {
      final key = '${e.key}';
      if (!key.startsWith('page_') && !key.startsWith('topic_')) continue;
      final room = e.value;
      if (room is! Map) continue;
      final meta = room['meta'];
      final last = meta is Map
          ? (meta['lastMessageAt'] as num?)?.toInt() ?? 0
          : 0;
      if (last > 0 && last < cutoff) {
        await _db!.child('rooms/$key').remove();
        removed++;
      }
    }
    return removed;
  }

  Future<OnlineUser?> findByPublicId(String id) async {
    final pid = id.trim().toUpperCase();
    if (pid.isEmpty || _db == null) return null;
    // Online trước
    for (final u in onlineUsers) {
      if (u.publicId.toUpperCase() == pid) return u;
    }
    final map = await _db!.child('publicIds/$pid').get();
    final uid = map.value as String?;
    if (uid == null) return null;
    final prof = await _db!.child('users/$uid').get();
    if (prof.value is! Map) {
      return OnlineUser(
        uid: uid,
        publicId: pid,
        name: 'User $pid',
        lastSeen: 0,
      );
    }
    final m = Map<String, dynamic>.from(prof.value as Map);
    return OnlineUser(
      uid: uid,
      publicId: pid,
      name: '${m['displayName'] ?? 'User'}',
      photoUrl: m['photoUrl'] as String?,
      lastSeen: 0,
      nameOrdinal: (m['nameOrdinal'] as num?)?.toInt() ?? 1,
      rank: '${m['rank'] ?? 'member'}',
    );
  }
}

final chatService = ChatService();
