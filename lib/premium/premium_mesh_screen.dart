import 'dart:async';

import 'package:flutter/material.dart';

import '../mesh/mesh_identity.dart';
import '../mesh/mesh_screen.dart';
import 'kinh_mesh_channel.dart';
import 'premium_mode_service.dart';

/// UI Premium: hybrid mesh + call 1-hop (native nếu có, fallback UDP LAN).
class PremiumMeshScreen extends StatefulWidget {
  const PremiumMeshScreen({super.key});

  @override
  State<PremiumMeshScreen> createState() => _PremiumMeshScreenState();
}

class _PremiumMeshScreenState extends State<PremiumMeshScreen> {
  final _ctrl = TextEditingController();
  final _lines = <String>[];
  StreamSubscription? _textSub;
  StreamSubscription? _callSub;
  bool _native = false;
  String _status = 'Đang khởi tạo…';
  bool _inCall = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await premiumModeService.load();
    await meshIdentity.loadOrCreate();
    _native = await kinhMeshChannel.isNativeAvailable;
    if (_native) {
      await kinhMeshChannel.start(
        publicId: meshIdentity.publicId ?? 'UNKNOWN',
        displayName: meshIdentity.displayName,
      );
      _textSub = kinhMeshChannel.incomingText.stream.listen((m) {
        setState(() {
          _lines.add('${m['fromName']}: ${m['text']}');
        });
      });
      _callSub = kinhMeshChannel.callEvents.stream.listen((e) {
        setState(() {
          _inCall = e['state'] == 'active' || e['state'] == 'incoming';
          _status = 'Call: ${e['state']}';
        });
      });
      setState(() => _status = 'Native mesh BLE+WFD sẵn sàng');
    } else {
      setState(() => _status =
          'Native chưa có trong APK → dùng fallback Chat gần (LAN). '
          'Gắn tool/android_mesh qua CI để bật BLE+WFD.');
    }
  }

  @override
  void dispose() {
    _textSub?.cancel();
    _callSub?.cancel();
    kinhMeshChannel.stop();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final survival = premiumModeService.mode == PremiumMeshMode.survival;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Mesh'),
        actions: [
          TextButton(
            onPressed: () async {
              final next = survival
                  ? PremiumMeshMode.auto
                  : PremiumMeshMode.survival;
              await premiumModeService.setMode(next);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    next == PremiumMeshMode.survival
                        ? 'Sinh tồn: ưu tiên mesh, giảm tải WebView/Firebase'
                        : 'Tự động: Firebase khi có mạng + mesh',
                  ),
                ),
              );
            },
            child: Text(survival ? 'Sinh tồn' : 'Tự động'),
          ),
        ],
      ),
      body: Column(
        children: [
          MaterialBanner(
            content: Text(
              '$_status\nID ${meshIdentity.publicId} · '
              '${_native ? "BLE dò + WFD khi cần · Call 1-hop" : "Fallback LAN"}\n'
              'Multi-hop voice / 2–4km chỉ ĐT: không cam kết.',
              style: const TextStyle(fontSize: 12),
            ),
            actions: [
              if (!_native)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MeshScreen()),
                    );
                  },
                  child: const Text('LAN mesh'),
                ),
            ],
          ),
          SizedBox(
            height: 64,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              children: [
                ...kinhMeshChannel.peers.values.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text('${p.name}\n${p.transport} ${p.rssi}'),
                      onPressed: () async {
                        await kinhMeshChannel.startCall(p.id);
                        setState(() {
                          _inCall = true;
                          _status = 'Gọi ${p.name} (1-hop WFD)…';
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_inCall)
            Padding(
              padding: const EdgeInsets.all(8),
              child: FilledButton.tonal(
                onPressed: () async {
                  await kinhMeshChannel.endCall();
                  setState(() {
                    _inCall = false;
                    _status = 'Đã kết thúc cuộc gọi';
                  });
                },
                child: const Text('Kết thúc cuộc gọi'),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _lines.length,
              itemBuilder: (_, i) => Text(_lines[i]),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(
                        hintText: 'Tin mesh…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final t = _ctrl.text.trim();
                      if (t.isEmpty) return;
                      if (_native) {
                        await kinhMeshChannel.broadcastText(t);
                      }
                      setState(() => _lines.add('Bạn: $t'));
                      _ctrl.clear();
                    },
                    icon: const Icon(Icons.send),
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
