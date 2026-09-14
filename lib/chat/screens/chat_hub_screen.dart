import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import 'chat_room_screen.dart';
import 'profile_screen.dart';

class ChatHubScreen extends StatefulWidget {
  final String? currentPageUrl;

  const ChatHubScreen({super.key, this.currentPageUrl});

  @override
  State<ChatHubScreen> createState() => _ChatHubScreenState();
}

class _ChatHubScreenState extends State<ChatHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _findCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    chatService.addListener(_onChat);
    chatService.init().then((_) async {
      if (chatService.isSignedIn) {
        await chatService.purgeInactiveRooms();
      }
      if (mounted) setState(() {});
    });
  }

  void _onChat() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    chatService.removeListener(_onChat);
    _tabs.dispose();
    _findCtrl.dispose();
    super.dispose();
  }

  Future<void> _ensureAuth() async {
    if (chatService.isSignedIn) return;
    await chatService.signIn();
    if (!mounted) return;
    if (!chatService.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            chatService.lastAuthError ??
                chatService.initError ??
                'Đăng nhập thất bại',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Xin chào ${chatService.displayName} · ID ${chatService.publicId}',
          ),
        ),
      );
      await chatService.purgeInactiveRooms();
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
    _openRoom(ChatService.dmRoomKey(me, otherUid), 'DM · $name', ChatService.maxDm);
  }

  Future<void> _findUser() async {
    await _ensureAuth();
    if (!chatService.isSignedIn) return;
    final u = await chatService.findByPublicId(_findCtrl.text);
    if (!mounted) return;
    if (u == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy ID')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    u.photoUrl != null ? NetworkImage(u.photoUrl!) : null,
                child: u.photoUrl == null ? Text(u.name[0]) : null,
              ),
              title: Text('${u.name} #${u.nameOrdinal}'),
              subtitle: Text('ID: ${u.publicId} · ${u.rank}'),
            ),
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('Nhắn riêng (DM)'),
              onTap: () {
                Navigator.pop(ctx);
                _openDm(u.uid, u.name);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final online = chatService.onlineUsers;
    final signed = chatService.isSignedIn;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cộng đồng Kính'),
        actions: [
          if (signed)
            IconButton(
              tooltip: 'Trang cá nhân',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChatProfileScreen()),
                );
              },
              icon: const Icon(Icons.person_outline),
            ),
          if (signed)
            IconButton(
              tooltip: 'Đăng xuất',
              onPressed: () async {
                await chatService.signOut();
                if (mounted) setState(() {});
              },
              icon: const Icon(Icons.logout),
            )
          else
            TextButton(
              onPressed: chatService.signingIn ? null : _ensureAuth,
              child: Text(chatService.signingIn ? '…' : 'Đăng nhập'),
            ),
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
              content: Text(chatService.initError!,
                  style: const TextStyle(fontSize: 12)),
              actions: [
                TextButton(
                  onPressed: () => chatService.init().then((_) => setState(() {})),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: signed
                ? const Color(0xFF1B5E20).withOpacity(0.35)
                : const Color(0xFF4A148C).withOpacity(0.25),
            child: Text(
              signed
                  ? '✅ ${chatService.displayName} #${chatService.nameOrdinal} · ID ${chatService.publicId} · 🟢 ${online.length} online'
                  : 'Chưa đăng nhập Google — bấm Đăng nhập (cần SHA-1 trong Firebase)',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                ListTile(
                  leading: const Icon(Icons.public),
                  title: const Text('Kênh thế giới'),
                  subtitle: const Text('~100 tin mới nhất'),
                  onTap: () => _openRoom(
                      'global', 'Kênh thế giới', ChatService.maxGlobal),
                ),
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
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      widget.currentPageUrl?.isNotEmpty == true
                          ? 'Trang: ${widget.currentPageUrl}'
                          : 'Mở Chat từ trình duyệt khi đang xem web, hoặc dán URL trong browser.',
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () {
                        final url = widget.currentPageUrl;
                        if (url == null || url.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Không có URL trang hiện tại'),
                            ),
                          );
                          return;
                        }
                        _openRoom(
                          ChatService.pageRoomKey(url),
                          'Chat trang',
                          ChatService.maxPage,
                        );
                      },
                      icon: const Icon(Icons.language),
                      label: const Text('Vào chat theo URL'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Phòng page/topic không nhắn 30 ngày sẽ tự xóa khi có người mở Cộng đồng.',
                      style: TextStyle(
                          fontSize: 12, color: Theme.of(context).hintColor),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _findCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Tìm ID (vd. A1B2C3)',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              textCapitalization: TextCapitalization.characters,
                            ),
                          ),
                          IconButton(
                            onPressed: _findUser,
                            icon: const Icon(Icons.search),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: online.isEmpty
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
                                        ? Text(u.name.isNotEmpty
                                            ? u.name[0]
                                            : '?')
                                        : null,
                                  ),
                                  title: Text(
                                      '${u.name} #${u.nameOrdinal}${me ? ' (bạn)' : ''}'),
                                  subtitle: Text(
                                      'ID ${u.publicId} · ${u.rank}'),
                                  trailing: me
                                      ? null
                                      : IconButton(
                                          icon: const Icon(Icons.mail_outline),
                                          onPressed: () =>
                                              _openDm(u.uid, u.name),
                                        ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
