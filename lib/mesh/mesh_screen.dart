import 'dart:async';

import 'package:flutter/material.dart';

import '../premium/kinh_mesh_channel.dart';
import 'local_mesh_service.dart';
import 'mesh_identity.dart';

/// Chat offline thống nhất: LAN (Wi‑Fi/hotspot) + Premium native BLE/WFD nếu APK có plugin.
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
    // LAN luôn bật khi mở màn (cần Wi‑Fi/hotspot)
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
      _status = 'Native BLE/WFD sẵn sàng — cấp quyền Bluetooth / Thiết bị gần trên **cả hai** máy';
    } else {
      _status =
          'Chỉ LAN (cùng Wi‑Fi/hotspot). APK chưa có native mesh hoặc build chưa inject.';
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
    // Giữ service nếu Premium cũng dùng; chỉ stop LAN khi rời màn chuẩn
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
      _lines.add(_Line(mine: true, name: 'Bạn', text: t, via: _native ? 'lan+ble' : 'lan'));
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _native
                ? 'Đã quét lại LAN + BLE. Kiểm tra quyền Bluetooth/Nearby trên cả 2 máy.'
                : 'Đã quét LAN. Cần cùng Wi‑Fi/hotspot.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lan = localMeshService;
    final blePeers = kinhMeshChannel.peers.values.toList();
    final lanPeers = lan.peers.values.toList();

    // Merge lines: LAN history + local _lines
    final allLines = <_Line>[
      ...lan.lines.map(
        (e) => _Line(
          mine: e.mine,
          name: e.fromName,
          text: e.text,
          via: e.storeForward ? 'sf' : 'lan',
        ),
      ),
      ..._lines.where((l) => !lan.lines.any((x) => x.text == l.text && x.mine == l.mine)),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat offline'),
        actions: [
          IconButton(
            tooltip: 'Quét lại',
            onPressed: _rescan,
            icon: const Icon(Icons.radar),
          ),
          TextButton(
            onPressed: () async {
              if (lan.running) {
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
                    'ID ${meshIdentity.publicId ?? "…"} · '
                    'LAN ${lanPeers.length} · BLE ${blePeers.length}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(_status, style: const TextStyle(fontSize: 11)),
                  const SizedBox(height: 6),
                  Text(
                    '• Cùng Wi‑Fi/hotspot → chat LAN (tắt Wi‑Fi là mất kênh này)\n'
                    '• BLE/WFD (native) → cần Bluetooth + quyền “Thiết bị gần” '
                    'trên CẢ HAI máy; không phụ thuộc Wi‑Fi\n'
                    '• Ảnh quyền chỉ Micro/Vị trí là chưa đủ cho BLE Android 12+',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (kinhMeshChannel.lastError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        kinhMeshChannel.lastError!,
                        style: const TextStyle(color: Colors.orangeAccent, fontSize: 11),
                      ),
                    ),
                  if (lan.lastError != null)
                    Text(lan.lastError!, style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
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
                    await meshIdentity.setDisplayName(_nameCtrl.text.trim());
                    if (_native && kinhMeshChannel.running) {
                      await kinhMeshChannel.stop();
                      await kinhMeshChannel.start(
                        publicId: meshIdentity.publicId ?? 'UNKNOWN',
                        displayName: meshIdentity.displayName,
                      );
                    }
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
                        label: Text('LAN ${p.name}', style: const TextStyle(fontSize: 11)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: line.mine
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!line.mine)
                          Text(
                            line.name,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
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
                    tooltip: 'Gửi ngay (LAN + BLE nếu có)',
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                  ),
                  IconButton(
                    tooltip: 'Store-and-Forward',
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
