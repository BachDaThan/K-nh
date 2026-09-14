import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import 'chat_room_screen.dart';

class ChatHubScreen extends StatefulWidget {
  /// URL trang web hiện tại (cho Page Chat). Có thể null.
  final String? currentPageUrl;

  const ChatHubScreen({super.key, this.currentPageUrl});

  @override
  State<ChatHubScreen> createState() => _ChatHubScreenState();
}

class _ChatHubScreenState extends State<ChatHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    chatService.init().then((_) {
      if (mounted) setState(() {});
    });
    chatService.addListener(_onChat);
  }

  void _onChat() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    chatService.removeListener(_onChat);
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _ensureAuth() async {
    if (chatService.isSignedIn) return;
    await chatService.signIn();
    if (!chatService.isSignedIn && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(chatService.initError ?? 'Đăng nhập Google để chat'),
        ),
      );
    }
  }

  void _openRoom(String key, String title, int maxKeep) async {
    await _ensureAuth();
    if (!chatService.isSignedIn || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          roomKey: key,
          title: title,
          maxKeep: maxKeep,
        ),
      ),
    );
  }

  void _openDm(String otherUid, String name) {
    final me = chatService.user?.uid;
    if (me == null) return;
    _openRoom(
      ChatService.dmRoomKey(me, otherUid),
      'DM · $name',
      ChatService.maxDm,
    );
  }

  @override
  Widget build(BuildContext context) {
    final online = chatService.onlineUsers;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cộng đồng Kính'),
        actions: [
          if (chatService.isSignedIn)
            IconButton(
              tooltip: 'Đăng xuất chat',
              onPressed: () => chatService.signOut(),
              icon: const Icon(Icons.logout),
            )
          else
            TextButton(onPressed: _ensureAuth, child: const Text('Đăng nhập')),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Thế giới'),
            Tab(text: 'Chủ đề'),
            Tab(text: 'Theo trang'),
            Tab(text: 'Online'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (chatService.initError != null)
            MaterialBanner(
              content: Text(chatService.initError!, style: const TextStyle(fontSize: 12)),
              actions: [
                TextButton(
                  onPressed: () => chatService.init().then((_) => setState(() {})),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              '🟢 ${online.length} đang online · text/emoji · giới hạn tin (Free Spark)',
              style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                // Global
                ListTile(
                  leading: const Icon(Icons.public),
                  title: const Text('Kênh thế giới'),
                  subtitle: const Text('Mọi người · giữ ~100 tin mới nhất'),
                  onTap: () => _openRoom(
                    'global',
                    'Kênh thế giới',
                    ChatService.maxGlobal,
                  ),
                ),
                // Topics
                ListView(
                  children: ChatService.topics.entries
                      .map(
                        (e) => ListTile(
                          leading: const Icon(Icons.tag),
                          title: Text(e.value),
                          onTap: () => _openRoom(
                            'topic_${e.key}',
                            e.value,
                            ChatService.maxTopic,
                          ),
                        ),
                      )
                      .toList(),
                ),
                // Page chat
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      widget.currentPageUrl == null ||
                              widget.currentPageUrl!.isEmpty
                          ? 'Mở từ trình duyệt (nút Chat trang) hoặc dán URL bên dưới.'
                          : 'Trang hiện tại:\n${widget.currentPageUrl}',
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () {
                        final url = widget.currentPageUrl;
                        if (url == null || url.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Không có URL — mở Chat từ trình duyệt khi đang xem web',
                              ),
                            ),
                          );
                          return;
                        }
                        final key = ChatService.pageRoomKey(url);
                        _openRoom(key, 'Chat trang', ChatService.maxPage);
                      },
                      icon: const Icon(Icons.language),
                      label: const Text('Vào chat theo URL trang'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tin page-chat tự dọn sau ~48h. Cùng URL → cùng phòng.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
                // Online + DM
                online.isEmpty
                    ? const Center(child: Text('Chưa thấy ai online'))
                    : ListView.builder(
                        itemCount: online.length,
                        itemBuilder: (_, i) {
                          final u = online[i];
                          final me = u.uid == chatService.user?.uid;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: u.photoUrl != null
                                  ? NetworkImage(u.photoUrl!)
                                  : null,
                              child: u.photoUrl == null
                                  ? Text(u.name.isNotEmpty ? u.name[0] : '?')
                                  : null,
                            ),
                            title: Text(u.name + (me ? ' (bạn)' : '')),
                            trailing: me
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.mail_outline),
                                    onPressed: () async {
                                      await _ensureAuth();
                                      if (chatService.isSignedIn) {
                                        _openDm(u.uid, u.name);
                                      }
                                    },
                                  ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
