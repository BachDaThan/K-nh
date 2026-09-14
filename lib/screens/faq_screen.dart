import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../legal/legal_urls.dart';

/// FAQ trong app (nội dung đồng bộ tinh thần FAQ.md trên repo).
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const _items = <(String, String)>[
    (
      'Không biết code có dùng được không?',
      'Có. Duyệt web, ghi chú, bookmark, chat gần/mesh local không cần viết code. '
          'Chỉ Cộng đồng online / Drive mới cần vài bước Google.',
    ),
    (
      'Bắt buộc đăng nhập Google?',
      'Không. Không đăng nhập vẫn dùng phần local. Google chỉ cho Cộng đồng và Drive (nếu bật).',
    ),
    (
      'Tác giả có đọc được tin nhắn?',
      'Chat LAN/Mesh: không qua server Kính. Cộng đồng Firebase: dữ liệu trên project Firebase — '
          'người có quyền Console có thể xem được; không muốn thì đừng dùng Cộng đồng.',
    ),
    (
      'Mesh có đi internet không?',
      'Không bắt buộc. LAN/Mesh là P2P. Không cam kết tầm vài km chỉ bằng điện thoại; gọi tốt nhất 1-hop.',
    ),
    (
      'Cập nhật có cài ngầm không?',
      'Không. Tải bản mới rồi bạn xác nhận cài.',
    ),
    (
      'Low-end mode / SOS / Xuất dữ liệu?',
      'Low-end: giảm animation, tối đa ~3 tab. SOS: broadcast tin cố định tới máy gần. '
          'Xuất: bookmark HTML, ghi chú MD, lịch sử CSV — không nhốt data.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FAQ · Riêng tư')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final e in _items)
            Card(
              child: ExpansionTile(
                title: Text(e.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
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
            title: const Text('Mở PRIVACY.md đầy đủ'),
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
