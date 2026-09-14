import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class MeshPeerInfo {
  final String id;
  final String name;
  final int rssi;
  final String transport; // ble | wfd

  MeshPeerInfo({
    required this.id,
    required this.name,
    this.rssi = 0,
    this.transport = 'ble',
  });

  factory MeshPeerInfo.fromMap(Map raw) => MeshPeerInfo(
        id: '${raw['id'] ?? ''}',
        name: '${raw['name'] ?? 'Peer'}',
        rssi: (raw['rssi'] as num?)?.toInt() ?? 0,
        transport: '${raw['transport'] ?? 'ble'}',
      );
}

/// Cầu Flutter ↔ Kotlin Mesh Service (Premium).
class KinhMeshChannel {
  static const _ch = MethodChannel('com.bachdathan.kinh/mesh');
  static const _ev = EventChannel('com.bachdathan.kinh/mesh_events');

  StreamSubscription? _sub;
  final peers = <String, MeshPeerInfo>{};
  final incomingText = StreamController<Map<String, String>>.broadcast();
  final callEvents = StreamController<Map<String, dynamic>>.broadcast();
  bool running = false;
  String? lastError;

  Future<bool> get isNativeAvailable async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final v = await _ch.invokeMethod<bool>('isAvailable');
      return v == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> start({required String publicId, required String displayName}) async {
    try {
      await _ch.invokeMethod('start', {
        'publicId': publicId,
        'displayName': displayName,
      });
      running = true;
      lastError = null;
      _sub ??= _ev.receiveBroadcastStream().listen(_onEvent, onError: (e) {
        lastError = '$e';
      });
    } on MissingPluginException {
      lastError =
          'Native mesh chưa gắn vào APK (cần CI copy tool/android_mesh). Dùng Chat gần UDP tạm.';
      running = false;
    } catch (e) {
      lastError = '$e';
      running = false;
    }
  }

  Future<void> stop() async {
    try {
      await _ch.invokeMethod('stop');
    } catch (_) {}
    running = false;
    peers.clear();
  }

  Future<void> sendText(String peerId, String text) async {
    await _ch.invokeMethod('sendText', {'peerId': peerId, 'text': text});
  }

  Future<void> broadcastText(String text) async {
    await _ch.invokeMethod('broadcastText', {'text': text});
  }

  /// Voice call 1-hop qua Wi‑Fi Direct.
  Future<void> startCall(String peerId) async {
    await _ch.invokeMethod('startCall', {'peerId': peerId});
  }

  Future<void> endCall() async {
    await _ch.invokeMethod('endCall');
  }

  void _onEvent(dynamic e) {
    if (e is! Map) return;
    final type = '${e['type']}';
    switch (type) {
      case 'peer':
        final p = MeshPeerInfo.fromMap(Map<String, dynamic>.from(e));
        if (p.id.isNotEmpty) peers[p.id] = p;
        break;
      case 'peerLost':
        peers.remove('${e['id']}');
        break;
      case 'text':
        incomingText.add({
          'fromId': '${e['fromId']}',
          'fromName': '${e['fromName'] ?? ''}',
          'text': '${e['text']}',
        });
        break;
      case 'call':
        callEvents.add(Map<String, dynamic>.from(e));
        break;
      case 'error':
        lastError = '${e['message']}';
        break;
    }
  }

  void dispose() {
    _sub?.cancel();
    incomingText.close();
    callEvents.close();
  }
}

final kinhMeshChannel = KinhMeshChannel();
