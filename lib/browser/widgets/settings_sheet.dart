import 'package:flutter/material.dart';
import '../engine/browser_engine.dart';
import '../models/doh_provider.dart';
import '../services/doh_service.dart';
import '../services/download_service.dart';
import '../services/password_service.dart';
import '../services/search_diversity.dart';

class SettingsSheet extends StatefulWidget {
  final DohService dohService;
  final SearchDiversityService diversityService;
  final PasswordService passwordService;
  final DownloadService downloadService;
  final BrowserEngine engine;
  final VoidCallback onChanged;

  const SettingsSheet({
    super.key,
    required this.dohService,
    required this.diversityService,
    required this.passwordService,
    required this.downloadService,
    required this.engine,
    required this.onChanged,
  });

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late double _diversity;
  final _customDohController = TextEditingController();

  late String _dohSelectedId;

  @override
  void initState() {
    super.initState();
    _diversity = widget.diversityService.index;
    _dohSelectedId = widget.dohService.current.id;
    if (widget.dohService.current.isCustom) {
      _customDohController.text = widget.dohService.current.url;
    }
  }

  @override
  void dispose() {
    _customDohController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Cài đặt trình duyệt',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Engine hiện tại: Chromium / WebView2\n'
              '(Kiến trúc đã chuẩn bị để swap sang GeckoView sau này)',
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
            ),
            const Divider(height: 32),

            // DoH
            const Text('DNS-over-HTTPS (DoH)',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...DohProvider.presets.map((p) {
              return RadioListTile<String>(
                dense: true,
                title: Text(p.name, style: const TextStyle(fontSize: 14)),
                value: p.id,
                groupValue: _dohSelectedId,
                onChanged: (_) async {
                  setState(() => _dohSelectedId = p.id);
                  await widget.dohService.setProvider(p);
                  widget.onChanged();
                },
                activeColor: const Color(0xFF6C8CFF),
                selected: _dohSelectedId == p.id,
              );
            }),
            RadioListTile<String>(
              dense: true,
              title: const Text('DoH tùy chỉnh (NextDNS / AdGuard Home...)',
                  style: TextStyle(fontSize: 14)),
              value: 'custom',
              groupValue: _dohSelectedId,
              onChanged: (_) {
                // Bật chế độ custom ngay — hiện ô nhập URL
                setState(() => _dohSelectedId = 'custom');
              },
              activeColor: const Color(0xFF6C8CFF),
              selected: _dohSelectedId == 'custom',
            ),
            if (_dohSelectedId == 'custom')
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 8, bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customDohController,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'https://dns.nextdns.io/xxxxx',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        final url = _customDohController.text.trim();
                        if (url.startsWith('https://')) {
                          await widget.dohService.setCustomUrl(url);
                          widget.onChanged();
                          setState(() => _dohSelectedId = 'custom');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã lưu DoH tùy chỉnh'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Lưu'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Lưu ý: System WebView chưa hỗ trợ DoH tầng network như GeckoView. '
              'Preference được lưu sẵn; khi chuyển sang GeckoBrowserEngine sẽ inject thật.',
              style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4)),
            ),

            const Divider(height: 32),

            // Search Diversity
            Text(
              'Độ sáng tạo Search: ${widget.diversityService.label} '
              '(${_diversity.toStringAsFixed(2)})',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _diversity,
              min: 0.0,
              max: 2.0,
              divisions: 20,
              label: _diversity.toStringAsFixed(2),
              activeColor: const Color(0xFF6C8CFF),
              onChanged: (v) => setState(() => _diversity = v),
              onChangeEnd: (v) async {
                await widget.diversityService.setIndex(v);
                widget.onChanged();
              },
            ),
            Text(
              '0.0 = chỉ .gov/.edu/Wikipedia/báo lớn  ·  0.5 = tiêu chuẩn  ·  >1.0 = ngách/blog/forum',
              style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4)),
            ),

            const Divider(height: 32),

            // Zoom & Print
            ListTile(
              leading: const Icon(Icons.zoom_in),
              title: const Text('Zoom trang hiện tại'),
              subtitle: const Text('Dùng cử chỉ pinch hoặc nút bên dưới'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () async {
                      // Zoom được quản lý per-tab trong engine; UI đơn giản.
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () async {},
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('In / Xuất PDF trang hiện tại'),
              onTap: () async {
                // Cần tabId active — caller có thể mở rộng sau.
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đang gọi printToPdf trên engine...'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),

            const Divider(height: 32),

            ListTile(
              leading: const Icon(Icons.cleaning_services),
              title: const Text('Xóa cookie & cache'),
              onTap: () async {
                await widget.engine.clearCookies();
                await widget.engine.clearCache();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã xóa cookie và cache'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(
                  'Mật khẩu đã lưu (${widget.passwordService.items.length})'),
              onTap: () {
                // Có thể mở màn hình quản lý mật khẩu chi tiết sau.
              },
            ),
          ],
        );
      },
    );
  }
}
