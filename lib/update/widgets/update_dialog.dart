import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/update_service.dart';

/// Hiển thị dialog thông báo có bản cập nhật mới (nếu [info] != null và
/// [info.hasUpdate] == true). Gọi hàm này ở nơi thấy phù hợp (vd sau khi
/// Dashboard mount xong).
Future<void> showUpdateDialogIfNeeded(
  BuildContext context,
  UpdateInfo? info,
) async {
  if (info == null || !info.hasUpdate) return;
  if (!context.mounted) return;

  final service = UpdateService();

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: const Text('Có bản cập nhật mới'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kính v${info.latestVersion} đã có sẵn '
            '(đang dùng v${info.currentVersion}).',
          ),
          if (info.body != null && info.body!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              info.body!.trim(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Sẽ mở trình duyệt để tải — bạn tự bấm cài, app không tự '
            'cài ngầm.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Để sau'),
        ),
        FilledButton(
          onPressed: () async {
            final url = service.downloadUrlFor(info);
            Navigator.of(ctx).pop();
            if (url.isEmpty) return;
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: const Text('Tải bản mới'),
        ),
      ],
    ),
  );
}
