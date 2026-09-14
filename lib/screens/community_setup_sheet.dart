import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../chat/google_auth_config.dart';

/// Hướng dẫn Cộng đồng — tách rõ 2 nhóm để khỏi hiểu lầm.
class CommunitySetupSheet extends StatefulWidget {
  const CommunitySetupSheet({super.key});

  @override
  State<CommunitySetupSheet> createState() => _CommunitySetupSheetState();
}

class _CommunitySetupSheetState extends State<CommunitySetupSheet> {
  final _ctrl = TextEditingController();
  bool _loaded = false;
  /// 0 = user APK sẵn, 1 = tự build từ repo
  int _group = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await loadGoogleWebClientIdOverride();
    final id = kGoogleWebClientId;
    _ctrl.text = id.contains('REPLACE') ? '' : id;
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
      initialChildSize: 0.85,
      minChildSize: 0.45,
      maxChildSize: 0.98,
      builder: (_, scroll) {
        return ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              'Cộng đồng (chat online)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Không bắt buộc để duyệt web, ghi chú, chat gần / mesh offline.',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Bạn thuộc nhóm nào?',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('Cài APK có sẵn'),
                  icon: Icon(Icons.download_done, size: 18),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Tự build code'),
                  icon: Icon(Icons.code, size: 18),
                ),
              ],
              selected: {_group},
              onSelectionChanged: (s) => setState(() => _group = s.first),
            ),
            const SizedBox(height: 16),
            if (_group == 0) _groupEndUser(context) else _groupDeveloper(context),
          ],
        );
      },
    );
  }

  Widget _groupEndUser(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _card(
          context,
          title: 'Nhóm A — Chỉ tải APK từ Releases (Kinh.apk)',
          child: const Text(
            'Bạn không cần tạo Firebase, không cần biết SHA-1, '
            'không cần dán Web client ID.\n\n'
            'Làm lần lượt:\n'
            '1. Cài đúng file APK do nhà phát hành đăng trên GitHub Releases.\n'
            '2. Mở app → Cộng đồng → bấm Đăng nhập Google.\n'
            '3. Chọn tài khoản Google và cho phép.\n\n'
            'Phần Firebase + SHA-1 + Web client ID đã do người phát hành APK '
            'cấu hình sẵn một lần. Bạn chỉ dùng.',
            style: TextStyle(fontSize: 13, height: 1.35),
          ),
        ),
        const SizedBox(height: 10),
        _card(
          context,
          title: 'Nếu vẫn báo CONFIGURATION_NOT_FOUND / lỗi đăng nhập',
          child: const Text(
            'Không phải bạn “chưa đăng ký Firebase”.\n'
            'Thường là bản APK chưa khớp cấu hình phía nhà phát hành '
            '(thiếu SHA-1 keystore trên Firebase Console).\n\n'
            'Việc nên làm: báo nhà phát hành / chờ bản APK mới.\n'
            'Ô dán Web client ID bên dưới chỉ dùng khi được hướng dẫn cụ thể — '
            'user thường không cần đụng.',
            style: TextStyle(fontSize: 13, height: 1.35),
          ),
        ),
        const SizedBox(height: 12),
        ExpansionTile(
          title: const Text('Tuỳ chọn nâng cao (ít khi cần)'),
          subtitle: const Text('Chỉ khi nhà phát hành bảo bạn dán ID'),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: _pasteIdBlock(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _groupDeveloper(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _card(
          context,
          title: 'Nhóm B — Clone repo / tự build APK',
          child: const Text(
            'APK bạn build có chữ ký (SHA-1) khác bản phát hành công khai. '
            'Firebase sẽ từ chối đăng nhập nếu chưa cấu hình đúng.\n\n'
            'Bạn chọn một trong hai hướng:\n'
            '• Dùng Firebase project của chính bạn (khuyến nghị khi fork), hoặc\n'
            '• Dùng chung project có sẵn trong repo (nếu chủ project cho phép) '
            'và thêm SHA-1 keystore của bạn vào project đó.',
            style: TextStyle(fontSize: 13, height: 1.35),
          ),
        ),
        const SizedBox(height: 10),
        _card(
          context,
          title: 'Checklist bắt buộc khi tự build',
          child: const Text(
            '1. Firebase Console → Authentication → bật Google Sign-In.\n'
            '2. Project settings → app Android (package com.bachdathan.kinh '
            'hoặc package bạn đổi) → thêm SHA-1:\n'
            '   keytool -list -v -keystore <file-ký-apk-của-bạn>\n'
            '3. Authentication → Google → copy Web client ID '
            '(dạng ….apps.googleusercontent.com).\n'
            '4. Dán Web client ID vào ô bên dưới → Lưu (không cần sửa file code).\n'
            '5. Build lại / cài lại APK → mở Cộng đồng → Đăng nhập Google.\n\n'
            'Thiếu bước 2 (SHA-1) là nguyên nhân hay gặp nhất của '
            'CONFIGURATION_NOT_FOUND.',
            style: TextStyle(fontSize: 13, height: 1.35),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => launchUrl(
            Uri.parse('https://console.firebase.google.com/'),
            mode: LaunchMode.externalApplication,
          ),
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text('Mở Firebase Console'),
        ),
        const SizedBox(height: 12),
        Text(
          'Web client ID (bắt buộc với nhóm tự build)',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        _pasteIdBlock(context),
      ],
    );
  }

  Widget _pasteIdBlock(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_loaded)
          TextField(
            controller: _ctrl,
            decoration: const InputDecoration(
              labelText: 'Web client ID',
              hintText: '….apps.googleusercontent.com',
              border: OutlineInputBorder(),
              isDense: true,
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
                    'Đã lưu trên máy. Hãy mở lại Cộng đồng / khởi động lại app rồi đăng nhập.',
                  ),
                ),
              );
            }
          },
          child: const Text('Lưu Web client ID trên máy này'),
        ),
      ],
    );
  }

  Widget _card(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
