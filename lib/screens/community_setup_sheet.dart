import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../chat/google_auth_config.dart';

/// Wizard nhẹ: không bắt buộc; dán Web client ID trong app.
class CommunitySetupSheet extends StatefulWidget {
  const CommunitySetupSheet({super.key});

  @override
  State<CommunitySetupSheet> createState() => _CommunitySetupSheetState();
}

class _CommunitySetupSheetState extends State<CommunitySetupSheet> {
  final _ctrl = TextEditingController();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await loadGoogleWebClientIdOverride();
    _ctrl.text = kGoogleWebClientId.contains('REPLACE') ? '' : kGoogleWebClientId;
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, scroll) {
        return ListView(
          controller: scroll,
          padding: const EdgeInsets.all(16),
          children: [
            Text('Cộng đồng (tuỳ chọn)',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Không bắt buộc để duyệt web / chat gần / mesh.\n'
              'Chỉ cần khi muốn chat online qua Firebase + Google.',
              style: TextStyle(fontSize: 13),
            ),
            const Divider(height: 24),
            const Text('Bước 1 — Firebase Console',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Text(
              '• Project của app → Authentication → Sign-in method → bật Google\n'
              '• Project settings → app Android → thêm SHA-1 keystore release\n'
              '• Authentication → Google → copy Web client ID',
              style: TextStyle(fontSize: 12),
            ),
            TextButton(
              onPressed: () => launchUrl(
                Uri.parse('https://console.firebase.google.com/'),
                mode: LaunchMode.externalApplication,
              ),
              child: const Text('Mở Firebase Console'),
            ),
            const SizedBox(height: 12),
            const Text('Bước 2 — Dán Web client ID vào đây (không sửa code)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            if (_loaded)
              TextField(
                controller: _ctrl,
                decoration: const InputDecoration(
                  labelText: 'Web client ID',
                  hintText: '….apps.googleusercontent.com',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () async {
                await saveGoogleWebClientIdOverride(_ctrl.text);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Đã lưu. Mở lại tab Cộng đồng / khởi động lại app rồi đăng nhập.',
                      ),
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Lưu trong app'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Vẫn lỗi CONFIGURATION_NOT_FOUND?\n'
              '→ SHA-1 chưa khớp file APK đang cài, hoặc Google Sign-In chưa bật.',
              style: TextStyle(fontSize: 12, color: Colors.orangeAccent),
            ),
          ],
        );
      },
    );
  }
}
