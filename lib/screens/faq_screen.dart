import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../legal/legal_urls.dart';
import 'community_setup_sheet.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const _items = <(String, String)>[
    (
      'Không biết code có dùng được không?',
      'Có. Duyệt web, ghi chú, chat gần/mesh không cần code.',
    ),
    (
      'Bắt buộc đăng nhập Google?',
      'Không. Google chỉ cho Cộng đồng online và Drive (nếu bật).',
    ),
    (
      'Tôi chỉ cài APK sẵn — có cần Firebase/SHA-1 không?',
      'Không. Chỉ bấm Đăng nhập Google. SHA-1/Web client ID do nhà phát hành cấu hình. '
          'Chỉ người tự build code mới cần cấu hình.',
    ),
    (
      'Tác giả có đọc được tin nhắn?',
      'LAN/Mesh: không qua server Kính. Cộng đồng Firebase: trên cloud — '
          'người có quyền Console có thể xem; không muốn thì đừng dùng Cộng đồng.',
    ),
    (
      'Mesh có đi internet không?',
      'Không bắt buộc. P2P local. Không cam kết tầm vài km chỉ bằng điện thoại.',
    ),
    (
      'Cập nhật có cài ngầm không?',
      'Không. Tải xong bạn xác nhận cài.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FAQ · Riêng tư')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            color: Theme.of(context)
                .colorScheme
                .primaryContainer
                .withOpacity(0.35),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Cộng đồng — 2 nhóm:\n'
                '• Cài APK có sẵn → chỉ Đăng nhập Google.\n'
                '• Tự build code → cần SHA-1 + Web client ID.',
                style: TextStyle(height: 1.35),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.groups_outlined),
            title: const Text('Mở Hướng dẫn Cộng đồng (2 nhóm)'),
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const CommunitySetupSheet(),
            ),
          ),
          const Divider(),
          for (final e in _items)
            Card(
              child: ExpansionTile(
                title:
                    Text(e.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(e.$2),
                  ),
                ],
              ),
            ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('PRIVACY.md đầy đủ'),
            onTap: () => launchUrl(
              Uri.parse(LegalUrls.privacyPolicy),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
    );
  }
}
