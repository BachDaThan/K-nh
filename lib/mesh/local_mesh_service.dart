import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'mesh_identity.dart';
import 'store_forward_service.dart';

class MeshPeer {
  final String id;
  final String name;
  final InternetAddress address;
  final int port;
  DateTime lastSeen;

  MeshPeer({
    required this.id,
    required this.name,
    required this.address,
    required this.port,
    required this.lastSeen,
  });
}

class MeshChatLine {
  final String fromId;
  final String fromName;
  final String text;
  final DateTime at;
  final bool mine;
  final bool storeForward;

  MeshChatLine({
    required this.fromId,
    required this.fromName,
    required this.text,
    required this.at,
    required this.mine,
    this.storeForward = false,
  });
}

/// LAN/hotspot UDP + Store-and-Forward text (TTL hop).
class LocalMeshService extends ChangeNotifier {
  static const port = 47829;
  RawDatagramSocket? _sock;
  Timer? _beacon;
  Timer? _sfFlush;
  bool running = false;
  final Map<String, MeshPeer> peers = {};
  final List<MeshChatLine> lines = [];
  String? lastError;

  Future<void> start() async {
    if (running) return;
    await meshIdentity.loadOrCreate();
    await storeForwardService.load();
    try {
      _sock = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        port,
        reuseAddress: true,
        reusePort: true,
      );
      _sock!.broadcastEnabled = true;
      _sock!.listen(_onDatagram);
      running = true;
      lastError = null;
      _beacon = Timer.periodic(const Duration(seconds: 2), (_) => _sendBeacon());
      _sfFlush = Timer.periodic(const Duration(seconds: 5), (_) => flushStoreForward());
      _sendBeacon();
      flushStoreForward();
      notifyListeners();
    } catch (e) {
      lastError = '$e';
      running = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    _beacon?.cancel();
    _sfFlush?.cancel();
    _sock?.close();
    _sock = null;
    running = false;
    peers.clear();
    notifyListeners();
  }

  void _onDatagram(RawSocketEvent ev) {
    if (ev != RawSocketEvent.read || _sock == null) return;
    final dg = _sock!.receive();
    if (dg == null) return;
    try {
      final j = jsonDecode(utf8.decode(dg.data)) as Map<String, dynamic>;
      final type = j['t'] as String?;
      final id = j['id'] as String? ?? '';
      if (id.isEmpty || id == meshIdentity.publicId) {
        // still accept sf from others only
        if (type != 'sf') return;
      }
      final name = j['n'] as String? ?? id;
      if (id.isNotEmpty && id != meshIdentity.publicId) {
        peers[id] = MeshPeer(
          id: id,
          name: name,
          address: dg.address,
          port: dg.port,
          lastSeen: DateTime.now(),
        );
      }

      if (type == 'msg') {
        final text = j['m'] as String? ?? '';
        if (text.isNotEmpty && id != meshIdentity.publicId) {
          lines.add(MeshChatLine(
            fromId: id,
            fromName: name,
            text: text,
            at: DateTime.now(),
            mine: false,
          ));
          if (lines.length > 200) lines.removeRange(0, lines.length - 200);
        }
      } else if (type == 'sf') {
        final payload = j['p'];
        if (payload is Map) {
          storeForwardService
              .onReceive(Map<String, dynamic>.from(payload))
              .then((show) {
            if (show) {
              final p = SfPacket.fromJson(Map<String, dynamic>.from(payload));
              lines.add(MeshChatLine(
                fromId: p.fromId,
                fromName: p.fromName,
                text: '[S&F] ${p.text}',
                at: DateTime.now(),
                mine: false,
                storeForward: true,
              ));
              if (lines.length > 200) {
                lines.removeRange(0, lines.length - 200);
              }
              notifyListeners();
            }
            // relay rest of queue
            flushStoreForward();
          });
        }
      }

      final cut = DateTime.now().subtract(const Duration(seconds: 12));
      peers.removeWhere((_, p) => p.lastSeen.isBefore(cut));
      notifyListeners();
    } catch (_) {}
  }

  void _sendBeacon() {
    _broadcast({
      't': 'hi',
      'id': meshIdentity.publicId,
      'n': meshIdentity.displayName,
    });
  }

  void sendChat(String text) {
    final t = text.trim();
    if (t.isEmpty || !running) return;
    _broadcast({
      't': 'msg',
      'id': meshIdentity.publicId,
      'n': meshIdentity.displayName,
      'm': t,
    });
    lines.add(MeshChatLine(
      fromId: meshIdentity.publicId ?? '',
      fromName: meshIdentity.displayName,
      text: t,
      at: DateTime.now(),
      mine: true,
    ));
    notifyListeners();
  }

  /// Gửi text qua Store-and-Forward (giữ trên máy + broadcast; peer giữ/relay).
  Future<void> sendStoreForward(String text, {String? toId, int ttl = 5}) async {
    final t = text.trim();
    if (t.isEmpty || !running) return;
    final p = await storeForwardService.enqueueOutgoing(
      text: t,
      toId: toId,
      ttl: ttl,
    );
    _broadcast({
      't': 'sf',
      'id': meshIdentity.publicId,
      'n': meshIdentity.displayName,
      'p': p.toJson(),
    });
    lines.add(MeshChatLine(
      fromId: p.fromId,
      fromName: p.fromName,
      text: '[S&F] $t',
      at: DateTime.now(),
      mine: true,
      storeForward: true,
    ));
    notifyListeners();
  }

  void flushStoreForward() {
    if (!running) return;
    for (final p in storeForwardService.packetsToRelay()) {
      if (p.ttl <= 0) continue;
      _broadcast({
        't': 'sf',
        'id': meshIdentity.publicId,
        'n': meshIdentity.displayName,
        'p': p.toJson(),
      });
    }
  }

  void _broadcast(Map<String, dynamic> map) {
    final data = utf8.encode(jsonEncode(map));
    try {
      _sock?.send(data, InternetAddress('255.255.255.255'), port);
    } catch (e) {
      lastError = '$e';
      notifyListeners();
    }
  }
}

final localMeshService = LocalMeshService();
