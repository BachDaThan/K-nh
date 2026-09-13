import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'local_backup_service.dart';

class BackupSheet extends StatefulWidget {
  const BackupSheet({super.key});

  @override
  State<BackupSheet> createState() => _BackupSheetState();
}

class _BackupSheetState extends State<BackupSheet> {
  final _svc = LocalBackupService();
  final _ctrl = TextEditingController();
  String? _status;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    final json = await _svc.exportJson();
    _ctrl.text = json;
    await Clipboard.setData(ClipboardData(text: json));
    setState(() => _status = 'Đã export + copy clipboard (${json.length} ký tự)');
  }

  Future<void> _import() async {
    try {
      final n = await _svc.importJson(_ctrl.text);
      setState(() => _status = 'Đã import $n khóa. Mở lại app để thấy theme/DoH…');
    } catch (e) {
      setState(() => _status = 'Lỗi import: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (ctx, scroll) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scroll,
            children: [
              const Text('Backup / Sync local',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                'Xuất JSON cấu hình (theme, DoH, bookmark keys…). '
                'Không gồm API key (secure storage). '
                'Google Drive / Gist: dán JSON thủ công — 0 server.',
                style: TextStyle(
                    fontSize: 12, color: Theme.of(context).hintColor),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: _export,
                    icon: const Icon(Icons.upload_outlined),
                    label: const Text('Export + Copy'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _import,
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Import'),
                  ),
                ],
              ),
              if (_status != null) ...[
                const SizedBox(height: 8),
                Text(_status!, style: const TextStyle(fontSize: 13)),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _ctrl,
                maxLines: 12,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Dán JSON backup vào đây để Import…',
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }
}
