import 'package:flutter/material.dart';
import 'local_mesh_service.dart';
import 'mesh_identity.dart';

/// Chat gần offline (LAN/hotspot) — bản chuẩn & Plus.
class MeshScreen extends StatefulWidget {
  const MeshScreen({super.key});

  @override
  State<MeshScreen> createState() => _MeshScreenState();
}

class _MeshScreenState extends State<MeshScreen> {
  final _ctrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    meshIdentity.loadOrCreate().then((_) {
      _nameCtrl.text = meshIdentity.displayName;
      setState(() {});
    });
    localMeshService.addListener(_on);
  }

  void _on() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    localMeshService.removeListener(_on);
    localMeshService.stop();
    _ctrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = localMeshService;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat gần (offline)'),
        actions: [
          if (s.running)
            TextButton(
              onPressed: () => s.stop(),
              child: const Text('Tắt'),
            )
          else
            TextButton(
              onPressed: () => s.start(),
              child: const Text('Bật mesh'),
            ),
        ],
      ),
      body: Column(
        children: [
          MaterialBanner(
            content: Text(
              s.running
                  ? 'ID ${meshIdentity.publicId} · ${s.peers.length} máy gần (cùng Wi‑Fi/hotspot, không cần internet)'
                  : 'Bật mesh khi đứng gần (cùng mạng LAN/hotspot). Không Google. '
                      'BLE đa hop kiểu Bitchat = Premium phase 2.',
              style: const TextStyle(fontSize: 12),
            ),
            actions: const [SizedBox.shrink()],
          ),
          if (s.lastError != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(s.lastError!, style: const TextStyle(color: Colors.redAccent)),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
                    await meshIdentity.setName(_nameCtrl.text);
                    setState(() {});
                  },
                  child: const Text('Lưu'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: s.peers.values
                  .map(
                    (p) => Padding(
                      padding: const EdgeInsets.all(4),
                      child: Chip(label: Text('${p.name} (${p.id})')),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: s.lines.length,
              itemBuilder: (_, i) {
                final m = s.lines[i];
                return Align(
                  alignment:
                      m.mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: m.mine
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!m.mine)
                          Text(m.fromName,
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold)),
                        Text(m.text),
                      ],
                    ),
                  ),
                );
              },
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
                      enabled: s.running,
                      decoration: const InputDecoration(
                        hintText: 'Tin nhắn offline…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) {
                        s.sendChat(_ctrl.text);
                        _ctrl.clear();
                      },
                    ),
                  ),
                  IconButton(
                    tooltip: 'Gửi ngay (LAN)',
                    onPressed: !s.running
                        ? null
                        : () {
                            s.sendChat(_ctrl.text);
                            _ctrl.clear();
                          },
                    icon: const Icon(Icons.send),
                  ),
                  IconButton(
                    tooltip: 'Store-and-Forward (giữ + relay khi gặp máy)',
                    onPressed: !s.running
                        ? null
                        : () async {
                            await s.sendStoreForward(_ctrl.text);
                            _ctrl.clear();
                          },
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
