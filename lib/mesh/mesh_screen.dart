import 'dart:async';

import 'package:flutter/material.dart';

import '../premium/kinh_mesh_channel.dart';
import '../services/mesh_permissions.dart';
import 'local_mesh_service.dart';
import 'mesh_identity.dart';

class MeshScreen extends StatefulWidget {
  const MeshScreen({super.key});

  @override
  State<MeshScreen> createState() => _MeshScreenState();
}

class _MeshScreenState extends State<MeshScreen> {
  final _ctrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _lines = <_Line>[];
  bool _native = false;
  StreamSubscription? _textSub;
  String _status = '';
  String? _permHint;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await meshIdentity.loadOrCreate();
    _nameCtrl.text = meshIdentity.displayName;
    localMeshService.addListener(_on);
    kinhMeshChannel.addListener(_on);

    // Xin quyền NGAY khi mở màn (Samsung thường hiện dialog; Xiaomi có thể không đủ)
    _permHint = await MeshPermissions.ensureForMesh();

    if (!localMeshService.running) {
      await localMeshService.start();
    }
    _native = await kinhMeshChannel.isNativeAvailable;
    if (_native) {
      await kinhMeshChannel.start(
        publicId: meshIdentity.publicId ?? 'UNKNOWN',
        displayName: meshIdentity.displayName,
      );
      _textSub = kinhMeshChannel.incomingText.stream.listen((m) {
        setState(() {
          _lines.add(_Line(
            mine: false,
            name: m['fromName'] ?? m['fromId'] ?? '?',
            text: m['text'] ?? '',
            via: 'ble',
          ));
        });
      });
      _status =
          'Native BLE/WFD: cần Bluetooth + quyền trên CẢ HAI máy (Samsung + Xiaomi).';
    } else {
      _status =
          'Chỉ LAN (Wi‑Fi/hotspot). APK chưa native hoặc inject lỗi.';
    }
    if (mounted) setState(() {});
  }

  void _on() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _textSub?.cancel();
    localMeshService.removeListener(_on);
    kinhMeshChannel.removeListener(_on);
    localMeshService.stop();
    if (kinhMeshChannel.running) {
      kinhMeshChannel.stop();
    }
    _ctrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    localMeshService.sendChat(t);
    if (_native && kinhMeshChannel.running) {
      try {
        await kinhMeshChannel.broadcastText(t);
      } catch (_) {}
    }
    setState(() {
      _lines.add(_Line(
        mine: true,
        name: 'Bạn',
        text: t,
        via: _native ? 'lan+ble' : 'lan',
      ));
    });
    _ctrl.clear();
  }

  Future<void> _sendSf() async {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    await localMeshService.sendStoreForward(t);
    setState(() {
      _lines.add(_Line(mine: true, name: 'Bạn', text: '[S&F] $t', via: 'sf'));
    });
    _ctrl.clear();
  }

  Future<void> _rescan() async {
    _permHint = await MeshPermissions.ensureForMesh();
    if (!localMeshService.running) await localMeshService.start();
    if (_native) {
      if (!kinhMeshChannel.running) {
        await kinhMeshChannel.start(
          publicId: meshIdentity.publicId ?? 'UNKNOWN',
          displayName: meshIdentity.displayName,
        );
      } else {
        await kinhMeshChannel.scan();
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final lan = localMeshService;
    final blePeers = kinhMeshChannel.peers.values.toList();
    final lanPeers = lan.peers.values.toList();
    final allLines = <_Line>[
      ...lan.lines.map(
        (e) => _Line(
          mine: e.mine,
          name: e.fromName,
          text: e.text,
          via: e.storeForward ? 'sf' : 'lan',
        ),
      ),
      ..._lines.where(
        (l) => !lan.lines.any((x) => x.text == l.text && x.mine == l.mine),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat offline'),
        actions: [
          IconButton(
            tooltip: 'Xin quyền + quét lại',
            onPressed: _rescan,
            icon: const Icon(Icons.radar),
          ),
          IconButton(
            tooltip: 'Mở Cài đặt quyền app',
            onPressed: () => MeshPermissions.openAppSettingsPage(),
            icon: const Icon(Icons.settings_applications),
          ),
          TextButton(
            onPressed: () async {
              if (lan.running || kinhMeshChannel.running) {
                await lan.stop();
                if (kinhMeshChannel.running) await kinhMeshChannel.stop();
              } else {
                await _boot();
              }
              setState(() {});
            },
            child: Text(lan.running || kinhMeshChannel.running ? 'Tắt' : 'Bật'),
          ),
        ],
      ),
      body: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ID ${meshIdentity.publicId ?? "…"} · LAN ${lanPeers.length} · BLE ${blePeers.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_status, style: const TextStyle(fontSize: 11)),
                  if (_permHint != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _permHint!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    'Xiaomi: nếu không thấy “Thiết bị gần”, vào Cài đặt → Ứng dụng → '
                    'Kính → Quyền (hoặc Quyền khác) → bật Bluetooth / Thiết bị gần thủ công. '
                    'Samsung thường hiện hộp thoại khi app xin.\n'
                    'LAN cần Wi‑Fi/hotspot; BLE cần BT + quyền cả 2 máy.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (kinhMeshChannel.lastError != null)
                    Text(
                      kinhMeshChannel.lastError!,
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên offline',
                      isDense: true,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await meshIdentity.setName(_nameCtrl.text.trim());
                    setState(() {});
                  },
                  child: const Text('Lưu'),
                ),
              ],
            ),
          ),
          if (lanPeers.isNotEmpty || blePeers.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  for (final p in lanPeers)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Chip(
                        label: Text(
                          'LAN ${p.name}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  for (final p in blePeers)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Chip(
                        avatar: const Icon(Icons.bluetooth, size: 14),
                        label: Text(
                          '${p.name} ${p.distanceLabel}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: allLines.length,
              itemBuilder: (_, i) {
                final line = allLines[i];
                return Align(
                  alignment:
                      line.mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: line.mine
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!line.mine)
                          Text(
                            line.name,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        Text(line.text),
                        Text(
                          line.via,
                          style: TextStyle(
                            fontSize: 9,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(
                        hintText: 'Tin nhắn offline…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                  ),
                  IconButton(
                    onPressed: _sendSf,
                    icon: const Icon(Icons.outbox),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Line {
  final bool mine;
  final String name;
  final String text;
  final String via;
  _Line({
    required this.mine,
    required this.name,
    required this.text,
    required this.via,
  });
}
