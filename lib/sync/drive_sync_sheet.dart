import 'package:flutter/material.dart';
import 'drive_sync_service.dart';

class DriveSyncSheet extends StatefulWidget {
  final DriveSyncService service;

  const DriveSyncSheet({super.key, required this.service});

  @override
  State<DriveSyncSheet> createState() => _DriveSyncSheetState();
}

class _DriveSyncSheetState extends State<DriveSyncSheet> {
  final _clientIdCtrl = TextEditingController();
  String? _msg;
  bool _busy = false;
  List<DriveFileItem> _files = [];

  DriveSyncService get s => widget.service;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await s.loadPrefs();
    final id = await s.getSavedClientId();
    _clientIdCtrl.text = id ?? '';
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _clientIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() fn) async {
    setState(() {
      _busy = true;
      _msg = null;
    });
    try {
      await fn();
    } catch (e) {
      _msg = '$e';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (ctx, scroll) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ListView(
            controller: scroll,
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
              const Text('Google Drive Sync',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(
                'Đọc file JSON backup bạn đã upload lên Drive. '
                'Không upload ngược (readonly). Windows: dùng Export/Import JSON.',
                style: TextStyle(
                    fontSize: 12, color: Theme.of(context).hintColor),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _clientIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'OAuth Client ID (tuỳ chọn / iOS)',
                  hintText: 'xxxx.apps.googleusercontent.com',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 12),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                            await s.saveClientId(_clientIdCtrl.text);
                            _msg = 'Đã lưu Client ID';
                          }),
                  child: const Text('Lưu Client ID'),
                ),
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.isSignedIn
                    ? 'Đã vào: ${s.account?.email ?? ""}'
                    : 'Chưa đăng nhập Google'),
                trailing: s.isSignedIn
                    ? TextButton(
                        onPressed: _busy
                            ? null
                            : () => _run(() async {
                                  await s.signOut();
                                  _msg = 'Đã đăng xuất';
                                }),
                        child: const Text('Đăng xuất'),
                      )
                    : FilledButton(
                        onPressed: _busy
                            ? null
                            : () => _run(() async {
                                  final err = await s.signIn();
                                  _msg = err ?? 'Đăng nhập OK';
                                }),
                        child: const Text('Đăng nhập'),
                      ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tự động đồng bộ khi mở app'),
                subtitle: const Text('Tắt = chỉ khi bấm «Đồng bộ ngay»'),
                value: s.autoSync,
                onChanged: _busy
                    ? null
                    : (v) => _run(() async {
                          await s.setAutoSync(v);
                        }),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('File trên Drive'),
                subtitle: Text(
                  s.hasLinkedFile
                      ? '${s.fileName}\nID: ${s.fileId}'
                      : 'Chưa chọn — bấm «Chọn file»',
                ),
                isThreeLine: s.hasLinkedFile,
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _busy || !s.isSignedIn
                        ? null
                        : () => _run(() async {
                              _files = await s.listCandidateFiles();
                              if (_files.isEmpty) {
                                _msg = 'Không thấy file JSON trên Drive';
                                return;
                              }
                              if (!mounted) return;
                              final pick = await showDialog<DriveFileItem>(
                                context: context,
                                builder: (c) => SimpleDialog(
                                  title: const Text('Chọn file dữ liệu'),
                                  children: _files
                                      .map((f) => SimpleDialogOption(
                                            onPressed: () =>
                                                Navigator.pop(c, f),
                                            child: Text(
                                              '${f.name}\n${f.modifiedTime ?? ""}',
                                              style: const TextStyle(fontSize: 13),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              );
                              if (pick != null) {
                                await s.setLinkedFile(
                                    id: pick.id, name: pick.name);
                                _msg = 'Đã gắn: ${pick.name}';
                              }
                            }),
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Chọn file'),
                  ),
                  if (s.hasLinkedFile)
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                                await s.clearLinkedFile();
                                _msg = 'Đã bỏ liên kết file';
                              }),
                      child: const Text('Đổi / bỏ file'),
                    ),
                  FilledButton.icon(
                    onPressed: _busy || !s.hasLinkedFile
                        ? null
                        : () => _run(() async {
                              final err = await s.signIn();
                              if (err != null && !s.isSignedIn) {
                                _msg = err;
                                return;
                              }
                              _msg = await s.pullAndImport();
                            }),
                    icon: const Icon(Icons.sync),
                    label: const Text('Đồng bộ ngay'),
                  ),
                ],
              ),
              if (s.lastSyncMs != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Lần sync gần nhất: ${DateTime.fromMillisecondsSinceEpoch(s.lastSyncMs!)}',
                  style: TextStyle(
                      fontSize: 11, color: Theme.of(context).hintColor),
                ),
              ],
              if (_busy) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
              if (_msg != null) ...[
                const SizedBox(height: 12),
                Text(_msg!, style: const TextStyle(fontSize: 13)),
              ],
              const SizedBox(height: 16),
              Text(
                'Hướng dẫn Cloud Console: bật Drive API, OAuth Android '
                '(package com.bachdathan.kinh + SHA-1 keystore), upload file '
                'JSON backup (Export từ app) lên Drive rồi Chọn file tại đây.',
                style: TextStyle(
                    fontSize: 11, color: Theme.of(context).hintColor),
              ),
            ],
          ),
        );
      },
    );
  }
}
