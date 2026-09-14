import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../mesh/mesh_identity.dart';
import '../mesh/mesh_screen.dart';
import 'kinh_mesh_channel.dart';
import 'premium_mode_service.dart';
import '../services/sos_service.dart';

/// UX Sinh tồn: radar peer, ID, khoảng cách RSSI, WFD, chat, gọi 1-hop.
class PremiumMeshScreen extends StatefulWidget {
  const PremiumMeshScreen({super.key});

  @override
  State<PremiumMeshScreen> createState() => _PremiumMeshScreenState();
}

class _PremiumMeshScreenState extends State<PremiumMeshScreen>
    with TickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _lines = <_ChatLine>[];
  StreamSubscription? _textSub;
  StreamSubscription? _callSub;
  bool _native = false;
  String? _selectedPeerId;
  late AnimationController _radarCtrl;

  @override
  void initState() {
    super.initState();
    _radarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _boot();
  }

  Future<void> _boot() async {
    await premiumModeService.load();
    await meshIdentity.loadOrCreate();
    kinhMeshChannel.addListener(_onMesh);
    _native = await kinhMeshChannel.isNativeAvailable;
    if (_native) {
      await kinhMeshChannel.start(
        publicId: meshIdentity.publicId ?? 'UNKNOWN',
        displayName: meshIdentity.displayName,
      );
      _textSub = kinhMeshChannel.incomingText.stream.listen((m) {
        setState(() {
          _lines.add(_ChatLine(
            mine: false,
            name: m['fromName'] ?? m['fromId'] ?? '?',
            text: m['text'] ?? '',
          ));
        });
      });
      _callSub = kinhMeshChannel.callEvents.stream.listen((_) {
        if (mounted) setState(() {});
      });
    }
    if (mounted) setState(() {});
  }

  void _onMesh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _radarCtrl.dispose();
    _textSub?.cancel();
    _callSub?.cancel();
    kinhMeshChannel.removeListener(_onMesh);
    kinhMeshChannel.stop();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _toggleSurvival() async {
    final next = premiumModeService.mode == PremiumMeshMode.survival
        ? PremiumMeshMode.auto
        : PremiumMeshMode.survival;
    await premiumModeService.setMode(next);
    setState(() {});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          next == PremiumMeshMode.survival
              ? 'Sinh tồn: giao diện tối giản · ưu tiên mesh'
              : 'Tự động: có thể dùng Firebase khi có mạng',
        ),
      ),
    );
  }

  MeshPeerInfo? get _selected {
    final id = _selectedPeerId;
    if (id == null) return null;
    return kinhMeshChannel.peers[id];
  }

  @override
  Widget build(BuildContext context) {
    final survival = premiumModeService.mode == PremiumMeshMode.survival;
    final peers = kinhMeshChannel.peers.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));
    final inCall = kinhMeshChannel.wfdState == 'call';
    final bg = survival ? const Color(0xFF0A0E12) : Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: survival ? const Color(0xFF0D151C) : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(survival ? 'Sinh tồn · Mesh' : 'Premium Mesh'),
            Text(
              'ID ${meshIdentity.publicId ?? "…"}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'SOS nhanh',
            onPressed: () async {
              final r = await sosService.broadcast();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('SOS: $r')),
                );
              }
            },
            icon: const Icon(Icons.sos, color: Colors.redAccent),
          ),

          TextButton(
            onPressed: _toggleSurvival,
            child: Text(
              survival ? 'Sinh tồn' : 'Tự động',
              style: TextStyle(
                color: survival ? const Color(0xFF69F0AE) : null,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _statusBar(survival),
          SizedBox(
            height: survival ? 200 : 160,
            child: AnimatedBuilder(
              animation: _radarCtrl,
              builder: (_, __) => CustomPaint(
                painter: _RadarPainter(
                  progress: _radarCtrl.value,
                  peerCount: peers.length,
                  survival: survival,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cell_tower,
                        size: 28,
                        color: survival
                            ? const Color(0xFF69F0AE)
                            : Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        kinhMeshChannel.running
                            ? '${peers.length} peer · ${_wfdLabel()}'
                            : (_native ? 'Mesh tắt' : 'Không có native'),
                        style: TextStyle(
                          fontSize: 12,
                          color: survival ? Colors.white70 : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!_native)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MeshScreen()),
                  );
                },
                icon: const Icon(Icons.wifi_tethering),
                label: const Text('Fallback: Chat gần LAN/hotspot'),
              ),
            ),
          if (inCall) _callBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Row(
              children: [
                Text(
                  'Thiết bị gần',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: survival ? Colors.white : null,
                  ),
                ),
                const Spacer(),
                if (_native && !kinhMeshChannel.running)
                  TextButton(
                    onPressed: () async {
                      await kinhMeshChannel.start(
                        publicId: meshIdentity.publicId ?? 'X',
                        displayName: meshIdentity.displayName,
                      );
                      setState(() {});
                    },
                    child: const Text('Bật quét'),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 108,
            child: peers.isEmpty
                ? Center(
                    child: Text(
                      _native
                          ? 'Đang quét BLE… đưa máy gần nhau'
                          : 'Cần APK có CI inject mesh',
                      style: TextStyle(
                        fontSize: 12,
                        color: survival ? Colors.white54 : Colors.white54,
                      ),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: peers.length,
                    itemBuilder: (_, i) => _peerCard(peers[i], survival),
                  ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              decoration: BoxDecoration(
                color: survival
                    ? const Color(0xFF121A22)
                    : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: survival
                      ? const Color(0xFF1E3A2F)
                      : Colors.white12,
                ),
              ),
              child: _lines.isEmpty
                  ? Center(
                      child: Text(
                        'Chat mesh tối giản\nChọn peer hoặc broadcast',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: survival ? Colors.white38 : Colors.white38,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: _lines.length,
                      itemBuilder: (_, i) {
                        final m = _lines[i];
                        return Align(
                          alignment: m.mine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 7),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: m.mine
                                  ? const Color(0xFF1B5E20)
                                  : const Color(0xFF1A237E).withOpacity(0.55),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!m.mine)
                                  Text(
                                    m.name,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF69F0AE),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                Text(m.text, style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          if (_selected != null) _actionBar(_selected!, survival),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      style: TextStyle(color: survival ? Colors.white : null),
                      decoration: InputDecoration(
                        hintText: _selected == null
                            ? 'Broadcast mesh…'
                            : 'Nhắn ${_selected!.name}…',
                        hintStyle: const TextStyle(fontSize: 13),
                        isDense: true,
                        filled: true,
                        fillColor: survival ? const Color(0xFF121A22) : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBar(bool survival) {
    final err = kinhMeshChannel.lastError;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: err != null
          ? Colors.red.shade900.withOpacity(0.5)
          : (survival
              ? const Color(0xFF0D2818)
              : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.25)),
      child: Text(
        err ??
            'Bạn: ${meshIdentity.displayName} · ${meshIdentity.publicId} · '
                'Call chỉ 1-hop WFD · ${_wfdLabel()}',
        style: const TextStyle(fontSize: 11),
      ),
    );
  }

  String _wfdLabel() {
    switch (kinhMeshChannel.wfdState) {
      case 'forming':
        return 'WFD đang tạo nhóm…';
      case 'ready':
        return 'WFD sẵn sàng';
      case 'call':
        return 'Đang gọi';
      default:
        return 'WFD idle';
    }
  }

  Widget _callBanner() {
    final p = kinhMeshChannel.activeCallPeer;
    final name = p != null ? (kinhMeshChannel.peers[p]?.name ?? p) : '…';
    return Material(
      color: const Color(0xFF004D40),
      child: ListTile(
        leading: const Icon(Icons.call, color: Color(0xFF69F0AE)),
        title: Text('Đang gọi · $name'),
        subtitle: const Text('1-hop Wi‑Fi Direct · PCM'),
        trailing: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () async {
            await kinhMeshChannel.endCall();
            setState(() {});
          },
          child: const Text('Kết thúc'),
        ),
      ),
    );
  }

  Widget _peerCard(MeshPeerInfo p, bool survival) {
    final sel = p.id == _selectedPeerId;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedPeerId = p.id);
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 132,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: sel ? const Color(0xFF69F0AE) : Colors.white12,
              width: sel ? 2 : 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: survival
                  ? [
                      const Color(0xFF143D2C),
                      const Color(0xFF0E1A14),
                    ]
                  : [
                      Theme.of(context).colorScheme.primary.withOpacity(0.25),
                      Theme.of(context).colorScheme.surface,
                    ],
            ),
            boxShadow: sel
                ? [
                    BoxShadow(
                      color: const Color(0xFF69F0AE).withOpacity(0.35),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    p.transport == 'wfd' ? Icons.wifi : Icons.bluetooth,
                    size: 14,
                    color: const Color(0xFF69F0AE),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                p.id,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Colors.white54),
              ),
              const Spacer(),
              Text(
                p.distanceLabel,
                style: const TextStyle(fontSize: 11, color: Color(0xFFB2FF59)),
              ),
              const SizedBox(height: 2),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: p.signal01,
                  minHeight: 3,
                  backgroundColor: Colors.white12,
                  color: const Color(0xFF69F0AE),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionBar(MeshPeerInfo p, bool survival) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () async {
                await kinhMeshChannel.startCall(p.id);
                setState(() {});
              },
              icon: const Icon(Icons.call),
              label: const Text('Gọi 1-hop'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: p.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã copy ID peer')),
              );
            },
            child: const Text('Copy ID'),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    if (_native && kinhMeshChannel.running) {
      final sel = _selectedPeerId;
      if (sel != null) {
        await kinhMeshChannel.sendText(sel, t);
      } else {
        await kinhMeshChannel.broadcastText(t);
      }
    }
    setState(() {
      _lines.add(_ChatLine(mine: true, name: 'Bạn', text: t));
    });
    _ctrl.clear();
  }
}

class _ChatLine {
  final bool mine;
  final String name;
  final String text;
  _ChatLine({required this.mine, required this.name, required this.text});
}

class _RadarPainter extends CustomPainter {
  final double progress;
  final int peerCount;
  final bool survival;

  _RadarPainter({
    required this.progress,
    required this.peerCount,
    required this.survival,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final maxR = math.min(size.width, size.height) * 0.42;
    final base = survival ? const Color(0xFF69F0AE) : const Color(0xFF6C8CFF);
    for (var i = 1; i <= 3; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = base.withOpacity(0.15 * i);
      canvas.drawCircle(c, maxR * (i / 3), paint);
    }
    final sweep = Paint()
      ..shader = SweepGradient(
        colors: [
          base.withOpacity(0.0),
          base.withOpacity(0.35),
        ],
        transform: GradientRotation(progress * math.pi * 2),
      ).createShader(Rect.fromCircle(center: c, radius: maxR));
    canvas.drawCircle(c, maxR, sweep);
    // peer blips
    final rnd = math.Random(peerCount + 7);
    for (var i = 0; i < peerCount; i++) {
      final ang = rnd.nextDouble() * math.pi * 2;
      final r = maxR * (0.35 + rnd.nextDouble() * 0.55);
      final p = c + Offset(math.cos(ang) * r, math.sin(ang) * r);
      canvas.drawCircle(p, 4, Paint()..color = base);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.progress != progress || old.peerCount != peerCount;
}
