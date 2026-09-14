import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../browser/services/bookmark_service.dart';
import '../browser/services/history_service.dart';
import '../services/data_export_service.dart';

class DataExportSheet extends StatefulWidget {
  const DataExportSheet({super.key});

  @override
  State<DataExportSheet> createState() => _DataExportSheetState();
}

class _DataExportSheetState extends State<DataExportSheet> {
  String? _lastPath;
  bool _busy = false;

  Future<void> _run(Future<dynamic> Function() job, String label) async {
    setState(() => _busy = true);
    try {
      final f = await job();
      final path = f.path as String;
      setState(() => _lastPath = path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xuất $label:\n$path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xuất: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Xuất dữ liệu (mở / chuẩn)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Bookmark → HTML (Chrome/Firefox) · Ghi chú → Markdown · '
            'Lịch sử → CSV. File nằm thư mục Documents/kinh_export.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy
                ? null
                : () => _run(() async {
                      final b = BookmarkService();
                      return dataExportService.exportBookmarksHtml(b);
                    }, 'bookmark HTML'),
            child: const Text('Xuất bookmark (.html)'),
          ),
          FilledButton.tonal(
            onPressed: _busy
                ? null
                : () => _run(
                      () => dataExportService.exportNotesMarkdown(),
                      'ghi chú MD',
                    ),
            child: const Text('Xuất ghi chú (.md)'),
          ),
          FilledButton.tonal(
            onPressed: _busy
                ? null
                : () => _run(() async {
                      final h = HistoryService();
                      return dataExportService.exportHistoryCsv(h);
                    }, 'lịch sử CSV'),
            child: const Text('Xuất lịch sử (.csv)'),
          ),
          if (_lastPath != null) ...[
            const SizedBox(height: 8),
            ListTile(
              dense: true,
              title: Text(_lastPath!, style: const TextStyle(fontSize: 11)),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _lastPath!));
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
