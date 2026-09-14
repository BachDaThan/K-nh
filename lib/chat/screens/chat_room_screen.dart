import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

class ChatRoomScreen extends StatefulWidget {
  final String roomKey;
  final String title;
  final int maxKeep;

  const ChatRoomScreen({
    super.key,
    required this.roomKey,
    required this.title,
    this.maxKeep = 100,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _ctrl.text;
    if (t.trim().isEmpty) return;
    try {
      await chatService.send(widget.roomKey, t, maxKeep: widget.maxKeep);
      _ctrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Color _rankColor(String rank) {
    switch (rank) {
      case 'admin':
        return const Color(0xFFFFD54F);
      case 'mod':
        return const Color(0xFF80CBC4);
      default:
        return const Color(0xFF90CAF9);
    }
  }

  Widget _nameChip(ChatMessage m) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          m.name,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _rankColor(m.rank),
            shadows: const [
              Shadow(color: Colors.black54, blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _rankColor(m.rank).withOpacity(0.9),
                _rankColor(m.rank).withOpacity(0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: _rankColor(m.rank).withOpacity(0.45),
                blurRadius: 6,
              ),
            ],
          ),
          child: Text(
            '#${m.nameOrdinal}',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        if (m.rank != 'member') ...[
          const SizedBox(width: 4),
          Icon(
            m.rank == 'admin' ? Icons.workspace_premium : Icons.shield,
            size: 12,
            color: _rankColor(m.rank),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = chatService.user?.uid;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title, maxLines: 1)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream:
                  chatService.watchRoom(widget.roomKey, limit: widget.maxKeep),
              builder: (ctx, snap) {
                final msgs = snap.data ?? [];
                if (msgs.isEmpty) {
                  return const Center(
                    child: Text('Chưa có tin — hãy chào mọi người'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final m = msgs[i];
                    final mine = m.uid == me;
                    return Align(
                      alignment:
                          mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.78,
                        ),
                        decoration: BoxDecoration(
                          color: mine
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!mine) _nameChip(m),
                            if (!mine) const SizedBox(height: 2),
                            Text(m.text),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(
                        hintText: 'Nhắn tin…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      maxLength: 500,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(onPressed: _send, icon: const Icon(Icons.send)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
