import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../engine/browser_engine.dart';
import '../models/doh_provider.dart';
import '../services/doh_service.dart';
import '../../legal/legal_urls.dart';
import '../services/download_service.dart';
import '../services/password_service.dart';
import '../services/search_diversity.dart';
import '../services/search_engine_service.dart';
import '../services/safe_browsing_service.dart';
import '../../perf/performance_service.dart';
import '../services/adblock_service.dart';
import '../services/web_cosmetics_service.dart';
import '../../reader/reader_settings.dart';

class SettingsSheet extends StatefulWidget {
  final DohService dohService;
  final SearchDiversityService diversityService;
  final PasswordService passwordService;
  final DownloadService downloadService;
  final BrowserEngine engine;
  final VoidCallback onChanged;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onOpenActivityLog;
  final VoidCallback? onOpenPrivacy;

  const SettingsSheet({
    super.key,
    required this.dohService,
    required this.diversityService,
    required this.passwordService,
    required this.downloadService,
    required this.engine,
    required this.onChanged,
    this.onOpenHistory,
    this.onOpenActivityLog,
    this.onOpenPrivacy,
  });

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late double _diversity;
  late String _engineId;
  final _customDohController = TextEditingController();

  late String _dohSelectedId;

  @override
  void initState() {
    super.initState();
    _diversity = widget.diversityService.index;
    safeBrowsingService.load().then((_) { if (mounted) setState(() {}); });
    performanceService.load().then((_) { if (mounted) setState(() {}); });
    _engineId = searchEngineService.currentId;
    adblockService.load().then((_) { if (mounted) setState(() {}); });
    webCosmeticsService.load().then((_) { if (mounted) setState(() {}); });
    readerSettings.load().then((_) { if (mounted) setState(() {}); });
    if (!widget.dohService.enabled) {
      _dohSelectedId = 'system';
    } else {
      _dohSelectedId = widget.dohService.current.id;
      if (widget.dohService.current.isCustom) {
        _customDohController.text = widget.dohService.current.url;
      }
    }
  }

  Future<void> _saveCustomDoh() async {
    final err = await widget.dohService.setCustomUrl(_customDohController.text);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent.shade700,
        ),
      );
      return;
    }
    setState(() {
      _dohSelectedId = 'custom';
      _customDohController.text = widget.dohService.current.url;
    });
    widget.onChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã lưu DoH: ${widget.dohService.current.url}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
              'Engine: Chromium / System WebView · WebView2\n'
              'GeckoView trial đã gỡ (xung đột plugin).',
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
            ),
            const Divider(height: 32),

            const Text('Bảo mật & Lịch sử (Bước 3)',
                style: TextStyle(fontWeight: FontWeight.w600)),
            ListTile(
              dense: true,
              leading: const Icon(Icons.history, size: 20),
              title: const Text('Lịch sử duyệt web'),
              onTap: () {
                Navigator.pop(context);
                widget.onOpenHistory?.call();
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.timeline, size: 20),
              title: const Text('Activity Log (minh bạch)'),
              onTap: () {
                Navigator.pop(context);
                widget.onOpenActivityLog?.call();
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.cleaning_services, size: 20),
              title: const Text('Dọn dẹp / xóa theo domain'),
              onTap: () {
                Navigator.pop(context);
                widget.onOpenPrivacy?.call();
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.visibility_off, size: 20),
              title: const Text('Tab ẩn danh'),
              subtitle: const Text('Nút mắt trên thanh tab — không ghi lịch sử',
                  style: TextStyle(fontSize: 11)),
              onTap: null,
            ),

            const Divider(height: 32),


            // DoH — UI kiểu "DNS bảo mật" Android (Private DNS)
            const Text('DNS bảo mật (DoH trong app)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sử dụng DNS bảo mật'),
              subtitle: const Text(
                'Chọn nhà cung cấp DoH trong app (không đổi DNS toàn máy)',
              ),
              value: widget.dohService.enabled,
              onChanged: (v) async {
                await widget.dohService.setEnabled(v);
                setState(() {});
                widget.onChanged();
              },
            ),
            if (widget.dohService.enabled) ...[
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                title: const Text('Theo DNS máy (không ép DoH app)'),
                subtitle: const Text('Giống “nhà cung cấp hiện tại” trên Android'),
                value: 'system',
                groupValue: _dohSelectedId,
                onChanged: (_) async {
                  setState(() => _dohSelectedId = 'system');
                  await widget.dohService.setEnabled(false);
                  setState(() {});
                  widget.onChanged();
                },
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4, bottom: 4),
                child: Text('Chọn nhà cung cấp khác',
                    style: TextStyle(fontWeight: FontWeight.w500)),
              ),
              ...DohProvider.presets.map((p) {
                return RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(p.name),
                  subtitle: p.subtitle != null ? Text(p.subtitle!) : null,
                  value: p.id,
                  groupValue: _dohSelectedId,
                  onChanged: (id) async {
                    if (id == null) return;
                    setState(() => _dohSelectedId = id);
                    await widget.dohService.setEnabled(true);
                    await widget.dohService.setProvider(p);
                    widget.onChanged();
                    setState(() {});
                  },
                  selected: _dohSelectedId == p.id,
                );
              }),
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tùy chỉnh'),
                subtitle: const Text('URL của nhà cung cấp (DoH)'),
                value: 'custom',
                groupValue: _dohSelectedId,
                onChanged: (_) {
                  setState(() => _dohSelectedId = 'custom');
                },
                selected: _dohSelectedId == 'custom',
              ),
              if (_dohSelectedId == 'custom')
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customDohController,
                          decoration: const InputDecoration(
                            labelText: 'URL DoH',
                            hintText: 'https://dns.nextdns.io/...',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _saveCustomDoh(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _saveCustomDoh,
                        child: const Text('Lưu'),
                      ),
                    ],
                  ),
                ),
            ],
            const Text(
              'Khác Private DNS hệ thống (DoT toàn máy): System WebView vẫn '
              'phân giải DNS theo máy. Muốn DNS cho cả điện thoại → Cài đặt Android '
              '→ Mạng → DNS bảo mật. Kính lưu DoH để UI thống nhất / engine sau này.',
              style: TextStyle(fontSize: 11),
            ),
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            ...SearchEngineService.engines.map((e) {
              return RadioListTile<String>(
                dense: true,
                title: Text(e.name, style: const TextStyle(fontSize: 14)),
                value: e.id,
                groupValue: _engineId,
                onChanged: (v) async {
                  if (v == null) return;
                  setState(() => _engineId = v);
                  await searchEngineService.setEngine(v);
                  widget.onChanged();
                },
              );
            }),
            const Divider(height: 24),

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

            const Divider(height: 32),
            const Text('Pháp lý', style: TextStyle(fontWeight: FontWeight.w600)),
            ListTile(
              dense: true,
              leading: const Icon(Icons.privacy_tip_outlined, size: 20),
              title: const Text('Chính sách quyền riêng tư'),
              subtitle: const Text('Bắt buộc khi đăng Play Store',
                  style: TextStyle(fontSize: 11)),
              onTap: () async {
                final uri = Uri.parse(LegalUrls.privacyPolicy);
                if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                  await launchUrl(Uri.parse(LegalUrls.privacyPolicyFallback),
                      mode: LaunchMode.externalApplication);
                }
              },
            ),

            const Text('Duyệt web an toàn', style: TextStyle(fontWeight: FontWeight.w600)),
            Text(
              '3 mức kiểu Chrome — chặn local, không gửi URL lên Google.',
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
            ),
            RadioListTile<SafeBrowsingLevel>(
              dense: true,
              title: const Text('Bảo vệ nâng cao'),
              subtitle: const Text('Siết host/TLD/IP/đuôi file nguy hiểm'),
              value: SafeBrowsingLevel.enhanced,
              groupValue: safeBrowsingService.level,
              onChanged: (v) async {
                if (v == null) return;
                await safeBrowsingService.setLevel(v);
                setState(() {});
              },
            ),
            RadioListTile<SafeBrowsingLevel>(
              dense: true,
              title: const Text('Bảo vệ tiêu chuẩn'),
              subtitle: const Text('Chặn host độc hại đã biết'),
              value: SafeBrowsingLevel.standard,
              groupValue: safeBrowsingService.level,
              onChanged: (v) async {
                if (v == null) return;
                await safeBrowsingService.setLevel(v);
                setState(() {});
              },
            ),
            RadioListTile<SafeBrowsingLevel>(
              dense: true,
              title: const Text('Không bảo vệ'),
              subtitle: const Text('Không khuyến nghị'),
              value: SafeBrowsingLevel.off,
              groupValue: safeBrowsingService.level,
              onChanged: (v) async {
                if (v == null) return;
                await safeBrowsingService.setLevel(v);
                setState(() {});
              },
            ),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Chế độ máy yếu'),
              subtitle: Text(performanceService.descriptionVi),
              value: performanceService.lowEndMode,
              onChanged: (v) async {
                await performanceService.setLowEnd(v);
                setState(() {});
              },
            ),
            const Divider(),
          ],
        );
      },
    );
  }
}
