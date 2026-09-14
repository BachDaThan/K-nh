import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/chat_service.dart';

class ChatProfileScreen extends StatefulWidget {
  const ChatProfileScreen({super.key});

  @override
  State<ChatProfileScreen> createState() => _ChatProfileScreenState();
}

class _ChatProfileScreenState extends State<ChatProfileScreen> {
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = chatService.displayName;
    chatService.addListener(_on);
  }

  void _on() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    chatService.removeListener(_on);
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final u = chatService.user;
    return Scaffold(
      appBar: AppBar(title: const Text('Trang cá nhân')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (u?.photoURL != null)
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(u!.photoURL!),
              ),
            ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              chatService.displayName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text(
              'ID: ${chatService.publicId ?? "—"}',
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
          ),
          TextButton.icon(
            onPressed: chatService.publicId == null
                ? null
                : () {
                    Clipboard.setData(
                        ClipboardData(text: chatService.publicId!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã copy ID')),
                    );
                  },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy ID'),
          ),
          const Divider(),
          const Text('Đổi tên hiển thị',
              style: TextStyle(fontWeight: FontWeight.w600)),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              hintText: 'Tên mới',
              border: OutlineInputBorder(),
            ),
            maxLength: 24,
          ),
          FilledButton(
            onPressed: () async {
              try {
                await chatService.setDisplayName(_nameCtrl.text);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Đã đổi tên · danh hiệu #${chatService.nameOrdinal}',
                      ),
                    ),
                  );
                  setState(() {});
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('$e')));
                }
              }
            },
            child: const Text('Lưu tên'),
          ),
          const SizedBox(height: 16),
          const Text('Danh hiệu tên',
              style: TextStyle(fontWeight: FontWeight.w600)),
          Text(
            'Ai đặt tên trước được số nhỏ hơn. Số hiện cạnh tên trong chat.',
            style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 8),
          if (chatService.nameTitles.isEmpty)
            const Text('Chưa có danh hiệu')
          else
            ...chatService.nameTitles.entries.map(
              (e) => ListTile(
                dense: true,
                title: Text(e.key),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C8CFF), Color(0xFFB388FF)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Color(0x886C8CFF), blurRadius: 8),
                    ],
                  ),
                  child: Text(
                    '#${e.value}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          const Divider(),
          ListTile(
            title: const Text('Rank'),
            subtitle: Text(chatService.rank),
            leading: const Icon(Icons.military_tech_outlined),
          ),
        ],
      ),
    );
  }
}
