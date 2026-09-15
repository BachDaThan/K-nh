import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class MeshPeerInfo {
  final String id;
  final String name;
  final int rssi;
  final String transport;
  final DateTime lastSeen;

  MeshPeerInfo({
    required this.id,
    required this.name,
    this.rssi = 0,
    this.transport = 'ble',
    DateTime? lastSeen,
  }) : lastSeen = lastSeen ?? DateTime.now();

  factory MeshPeerInfo.fromMap(Map raw) => MeshPeerInfo(
        id: '${raw['id'] ?? ''}',
        name: '${raw['name'] ?? 'Peer'}',
        rssi: (raw['rssi'] as num?)?.toInt() ?? 0,
        transport: '${raw['transport'] ?? 'ble'}',
      );

  String get distanceLabel {
    if (rssi == 0) return '—';
    if (rssi >= -55) return '~1–3 m';
    if (rssi >= -70) return '~3–8 m';
    if (rssi >= -85) return '~8–20 m';
    return '>20 m / yếu';
  }

  double get signal01 {
    final v = ((rssi + 100) / 60).clamp(0.0, 1.0);
    return v.toDouble();
  }
}

class KinhMeshChannel extends ChangeNotifier {
  static const _ch = MethodChannel('com.bachdathan.kinh/mesh');
  static const _ev = EventChannel('com.bachdathan.kinh/mesh_events');

  StreamSubscription? _sub;
  final peers = <String, MeshPeerInfo>{};
  final incomingText = StreamController<Map<String, String>>.broadcast();
  final callEvents = StreamController<Map<String, dynamic>>.broadcast();
  bool running = false;
  bool pluginPresent = false;
  String? lastError;
  String wfdState = 'idle';
  String? activeCallPeer;
  String statusLine = 'Chưa bật';

  Future<bool> get isNativeAvailable async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final v = await _ch.invokeMethod('isAvailable');
      pluginPresent = v == true || v is Map;
      return pluginPresent;
    } on MissingPluginException {
      pluginPresent = false;
      lastError =
          'Plugin mesh chưa gắn vào APK (CI inject / MainActivity). Dùng Chat gần LAN.';
      return false;
    } catch (e) {
      lastError = '$e';
      pluginPresent = false;
      return false;
    }
  }

  Future<void> start({required String publicId, required String displayName}) async {
    try {
      final r = await _ch.invokeMethod('start', {
        'publicId': publicId,
        'displayName': displayName,
      });
      running = true;
      lastError = null;
      statusLine = 'Đang quét BLE…';
      if (r is Map && '${r['status']}' == 'requesting_permissions') {
        statusLine = 'Đang xin quyền Bluetooth/Nearby…';
      }
      _sub ??= _ev.receiveBroadcastStream().listen(_onEvent, onError: (e) {
        lastError = '$e';
        notifyListeners();
      });
      notifyListeners();
    } on MissingPluginException {
      lastError =
          'Không có native mesh trong APK này. Cần build Android có bước CI inject mesh.';
      running = false;
      pluginPresent = false;
      notifyListeners();
    } catch (e) {
      lastError = '$e';
      running = false;
      notifyListeners();
    }
  }

  Future<void> scan() async {
    try {
      await _ch.invokeMethod('scan');
      statusLine = 'Quét lại…';
      notifyListeners();
    } catch (e) {
      lastError = '$e';
      notifyListeners();
    }
  }

  Future<void> stop() async {
    try {
      await _ch.invokeMethod('stop');
    } catch (_) {}
    running = false;
    peers.clear();
    wfdState = 'idle';
    activeCallPeer = null;
    statusLine = 'Đã tắt';
    notifyListeners();
  }

  Future<void> sendText(String peerId, String text) async {
    await _ch.invokeMethod('sendText', {'peerId': peerId, 'text': text});
  }

  Future<void> broadcastText(String text) async {
    wfdState = 'forming';
    notifyListeners();
    await _ch.invokeMethod('broadcastText', {'text': text});
    wfdState = 'ready';
    notifyListeners();
  }

  Future<void> startCall(String peerId) async {
    activeCallPeer = peerId;
    wfdState = 'call';
    notifyListeners();
    await _ch.invokeMethod('startCall', {'peerId': peerId});
  }

  Future<void> endCall() async {
    await _ch.invokeMethod('endCall');
    activeCallPeer = null;
    wfdState = 'ready';
    notifyListeners();
  }

  void _onEvent(dynamic e) {
    if (e is! Map) return;
    final type = '${e['type']}';
    switch (type) {
      case 'peer':
        final p = MeshPeerInfo.fromMap(Map<String, dynamic>.from(e));
        if (p.id.isNotEmpty) peers[p.id] = p;
        statusLine = '${peers.length} peer BLE';
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
        final st = '${e['state']}';
        if (st == 'active' || st == 'incoming') {
          wfdState = 'call';
          activeCallPeer = '${e['peerId'] ?? activeCallPeer}';
        } else if (st == 'ended') {
          wfdState = 'ready';
          activeCallPeer = null;
        }
        break;
      case 'status':
        statusLine = '${e['state']}';
        if (statusLine == 'started' || statusLine == 'scanning') running = true;
        break;
      case 'error':
        lastError = '${e['message']}';
        break;
    }
    notifyListeners();
  }

  void dispose() {
    _sub?.cancel();
    incomingText.close();
    callEvents.close();
  }
}

final kinhMeshChannel = KinhMeshChannel();
