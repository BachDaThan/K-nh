import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'mesh_identity.dart';

/// Một gói tin Store-and-Forward (chỉ **text**).
/// Máy trung gian giữ + chuyển khi gặp peer; TTL hop giới hạn vòng lặp.
class SfPacket {
  final String msgId;
  final String fromId;
  final String fromName;
  final String? toId; // null = broadcast gần
  final String text;
  final int ttl; // số hop còn lại
  final int createdMs;
  final Set<String> seenBy;

  SfPacket({
    required this.msgId,
    required this.fromId,
    required this.fromName,
    this.toId,
    required this.text,
    required this.ttl,
    required this.createdMs,
    Set<String>? seenBy,
  }) : seenBy = seenBy ?? {};

  Map<String, dynamic> toJson() => {
        'msgId': msgId,
        'fromId': fromId,
        'fromName': fromName,
        'toId': toId,
        'text': text,
        'ttl': ttl,
        'createdMs': createdMs,
        'seenBy': seenBy.toList(),
      };

  factory SfPacket.fromJson(Map<String, dynamic> j) => SfPacket(
        msgId: '${j['msgId']}',
        fromId: '${j['fromId']}',
        fromName: '${j['fromName'] ?? ''}',
        toId: j['toId'] == null ? null : '${j['toId']}',
        text: '${j['text'] ?? ''}',
        ttl: (j['ttl'] as num?)?.toInt() ?? 0,
        createdMs: (j['createdMs'] as num?)?.toInt() ?? 0,
        seenBy: {
          for (final x in (j['seenBy'] as List? ?? const [])) '$x',
        },
      );

  SfPacket decrementTtl(String myId) {
    final s = {...seenBy, myId};
    return SfPacket(
      msgId: msgId,
      fromId: fromId,
      fromName: fromName,
      toId: toId,
      text: text,
      ttl: ttl - 1,
      createdMs: createdMs,
      seenBy: s,
    );
  }
}

/// Hàng đợi S&F local — đồng bộ khi gặp peer (LAN mesh / gọi từ native sau).
/// Không phải Briar đầy đủ; không Nostr; không voice multi-hop.
class StoreForwardService extends ChangeNotifier {
  static const maxQueue = 80;
  static const defaultTtl = 5;
  static const maxAgeMs = 7 * 24 * 60 * 60 * 1000; // 7 ngày

  final List<SfPacket> queue = [];
  final Set<String> deliveredIds = {};
  final Set<String> seenIds = {};

  Future<File> _file() async {
    final d = await getApplicationDocumentsDirectory();
    return File('${d.path}/kinh_sf_queue.json');
  }

  Future<void> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return;
      final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      queue
        ..clear()
        ..addAll(
          (j['queue'] as List? ?? [])
              .map((e) => SfPacket.fromJson(Map<String, dynamic>.from(e as Map))),
        );
      deliveredIds
        ..clear()
        ..addAll((j['delivered'] as List? ?? []).map((e) => '$e'));
      seenIds
        ..clear()
        ..addAll((j['seen'] as List? ?? []).map((e) => '$e'));
      _purge();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final f = await _file();
      await f.writeAsString(
        jsonEncode({
          'queue': queue.map((e) => e.toJson()).toList(),
          'delivered': deliveredIds.toList(),
          'seen': seenIds.toList(),
        }),
      );
    } catch (_) {}
  }

  void _purge() {
    final now = DateTime.now().millisecondsSinceEpoch;
    queue.removeWhere(
      (p) => p.ttl <= 0 || now - p.createdMs > maxAgeMs,
    );
    while (queue.length > maxQueue) {
      queue.removeAt(0);
    }
  }

  String _newId() {
    final r = Random.secure().nextInt(1 << 32).toRadixString(16);
    final t = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    return '$t-$r';
  }

  /// Tạo gói gửi đi (lưu queue + trả về để broadcast ngay).
  Future<SfPacket> enqueueOutgoing({
    required String text,
    String? toId,
    int ttl = defaultTtl,
  }) async {
    await meshIdentity.loadOrCreate();
    final p = SfPacket(
      msgId: _newId(),
      fromId: meshIdentity.publicId ?? '?',
      fromName: meshIdentity.displayName,
      toId: toId,
      text: text.trim(),
      ttl: ttl,
      createdMs: DateTime.now().millisecondsSinceEpoch,
      seenBy: {meshIdentity.publicId ?? '?'},
    );
    seenIds.add(p.msgId);
    queue.add(p);
    _purge();
    await _save();
    notifyListeners();
    return p;
  }

  /// Nhận gói từ peer: nếu cho mình → delivered; nếu còn TTL → giữ để relay.
  /// Trả về true nếu đây là tin **mới cho mình** (hiện UI).
  Future<bool> onReceive(Map<String, dynamic> raw) async {
    final p = SfPacket.fromJson(raw);
    if (p.msgId.isEmpty || p.text.isEmpty) return false;
    if (seenIds.contains(p.msgId)) return false;
    seenIds.add(p.msgId);
    await meshIdentity.loadOrCreate();
    final me = meshIdentity.publicId ?? '';

    final forMe = p.toId == null || p.toId == me || p.toId!.isEmpty;
    var show = false;
    if (forMe && !deliveredIds.contains(p.msgId) && p.fromId != me) {
      deliveredIds.add(p.msgId);
      show = true;
    }

    // Store to relay if hops left and not only-for-me already delivered path
    if (p.ttl > 1) {
      final next = p.decrementTtl(me);
      if (!queue.any((q) => q.msgId == next.msgId)) {
        queue.add(next);
      }
    }
    _purge();
    await _save();
    notifyListeners();
    return show;
  }

  /// Gói cần broadcast khi gặp peer (còn TTL).
  List<SfPacket> packetsToRelay() {
    _purge();
    return List.unmodifiable(
      queue.where((p) => p.ttl > 0 && !deliveredIds.contains(p.msgId) || p.ttl > 0),
    );
  }

  /// Sau khi đã broadcast, có thể giảm TTL local bản copy.
  Future<void> markRelayed(String msgId) async {
    final i = queue.indexWhere((p) => p.msgId == msgId);
    if (i < 0) return;
    final p = queue[i];
    if (p.ttl <= 1) {
      queue.removeAt(i);
    } else {
      queue[i] = p.decrementTtl(meshIdentity.publicId ?? '');
    }
    await _save();
    notifyListeners();
  }
}

final storeForwardService = StoreForwardService();
