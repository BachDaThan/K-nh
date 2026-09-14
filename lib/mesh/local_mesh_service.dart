import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'mesh_identity.dart';

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

  MeshChatLine({
    required this.fromId,
    required this.fromName,
    required this.text,
    required this.at,
    required this.mine,
  });
}

/// Mesh **rút gọn** (chuẩn + Plus): LAN/hotspot UDP broadcast.
/// Không internet; cùng Wi‑Fi/hotspot là chat được.
/// BLE đa hop kiểu Bitchat = bản Premium native (phase 2) — xem docs/.
class LocalMeshService extends ChangeNotifier {
  static const port = 47829;
  RawDatagramSocket? _sock;
  Timer? _beacon;
  bool running = false;
  final Map<String, MeshPeer> peers = {};
  final List<MeshChatLine> lines = [];
  String? lastError;

  Future<void> start() async {
    if (running) return;
    await meshIdentity.loadOrCreate();
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
      _sendBeacon();
      notifyListeners();
    } catch (e) {
      lastError = '$e';
      running = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    _beacon?.cancel();
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
      if (id.isEmpty || id == meshIdentity.publicId) return;
      final name = j['n'] as String? ?? id;
      peers[id] = MeshPeer(
        id: id,
        name: name,
        address: dg.address,
        port: dg.port,
        lastSeen: DateTime.now(),
      );
      if (type == 'msg') {
        final text = j['m'] as String? ?? '';
        if (text.isNotEmpty) {
          lines.add(MeshChatLine(
            fromId: id,
            fromName: name,
            text: text,
            at: DateTime.now(),
            mine: false,
          ));
          if (lines.length > 200) lines.removeRange(0, lines.length - 200);
        }
      }
      // Drop stale peers
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
