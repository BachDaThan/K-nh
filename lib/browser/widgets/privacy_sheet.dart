import 'package:flutter/material.dart';
import '../engine/browser_engine.dart';
import '../services/activity_log_service.dart';
import '../services/history_service.dart';
import '../models/activity_event.dart';

class PrivacySheet extends StatefulWidget {
  final BrowserEngine engine;
  final HistoryService historyService;
  final ActivityLogService activityLog;
  final VoidCallback onChanged;

  const PrivacySheet({
    super.key,
    required this.engine,
    required this.historyService,
    required this.activityLog,
    required this.onChanged,
  });

  @override
  State<PrivacySheet> createState() => _PrivacySheetState();
}

class _PrivacySheetState extends State<PrivacySheet> {
  bool _busy = false;

  Future<void> _run(String label, Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(label),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      widget.onChanged();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final domains = widget.historyService.domains;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('Bảo mật & Dọn dẹp',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (_busy) const LinearProgressIndicator(minHeight: 2),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Xóa toàn bộ lịch sử'),
              subtitle: Text('${widget.historyService.items.length} mục'),
              onTap: () => _run('Đã xóa lịch sử', () async {
                await widget.historyService.clearAll();
                await widget.activityLog.log(
                  kind: ActivityKind.historyClear,
                  message: 'Xóa toàn bộ lịch sử',
                );
              }),
            ),
            ListTile(
              leading: const Icon(Icons.cookie_outlined),
              title: const Text('Xóa cookie'),
              onTap: () => _run('Đã xóa cookie', () async {
                await widget.engine.clearCookies();
                await widget.activityLog.log(
                  kind: ActivityKind.cookieClear,
                  message: 'Xóa cookie',
                );
              }),
            ),
            ListTile(
              leading: const Icon(Icons.cached),
              title: const Text('Xóa cache WebView'),
              onTap: () => _run('Đã xóa cache', () async {
                await widget.engine.clearCache();
                await widget.activityLog.log(
                  kind: ActivityKind.cacheClear,
                  message: 'Xóa cache WebView',
                );
              }),
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep),
              title: const Text('Xóa tất cả (lịch sử + cookie + cache + log)'),
              onTap: () => _run('Đã dọn sạch', () async {
                await widget.historyService.clearAll();
                await widget.engine.clearCookies();
                await widget.engine.clearCache();
                await widget.activityLog.clearAll();
                await widget.activityLog.log(
                  kind: ActivityKind.historyClear,
                  message: 'Dọn sạch toàn bộ dữ liệu duyệt',
                );
              }),
            ),
            if (domains.isNotEmpty) ...[
              const Divider(),
              const Text('Xóa lịch sử theo domain',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              ...domains.take(30).map((d) => ListTile(
                    dense: true,
                    title: Text(d),
                    trailing: const Icon(Icons.delete_outline, size: 18),
                    onTap: () => _run('Đã xóa lịch sử $d', () async {
                      await widget.historyService.clearDomain(d);
                      await widget.activityLog.log(
                        kind: ActivityKind.historyClear,
                        message: 'Xóa lịch sử domain $d',
                        url: 'https://$d',
                      );
                    }),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
