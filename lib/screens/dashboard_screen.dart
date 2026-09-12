import 'package:flutter/material.dart';
import '../models/bento_item.dart';
import '../widgets/bento_card.dart';
import '../browser/screens/browser_screen.dart';
import '../ai/screens/ai_builder_screen.dart';
import '../update/services/update_service.dart';
import '../update/services/hot_update_service.dart';
import '../update/widgets/update_dialog.dart';

/// Trang Dashboard trung tâm — tab cố định đầu tiên.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _updateService = UpdateService();
  final _hotUpdateService = HotUpdateService();
  String? _dashboardNotice;

  @override
  void initState() {
    super.initState();
    // Check update sau khi frame đầu vẽ xong, không chặn UI khởi động.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUpdate();
      _checkHotPatch();
    });
  }

  Future<void> _checkUpdate({bool force = false}) async {
    final info = await _updateService.check(force: force);
    if (!mounted) return;
    if (info != null && info.hasUpdate) {
      await showUpdateDialogIfNeeded(context, info);
    } else if (force) {
      // Chỉ báo "đã mới nhất" khi người dùng chủ động bấm kiểm tra —
      // check tự động lúc mở app thì im lặng nếu không có gì mới.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang dùng bản mới nhất.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _checkHotPatch() async {
    // Chữ ký đã được HotUpdateService verify trước khi trả về patch —
    // tới đây coi như nội dung đáng tin cậy.
    final patch = await _hotUpdateService.fetchAndVerify();
    if (!mounted || patch == null) return;
    if (patch.dashboardNotice != null &&
        patch.dashboardNotice!.trim().isNotEmpty) {
      setState(() => _dashboardNotice = patch.dashboardNotice);
    }
    if (patch.runnerHtml != null && patch.runnerHtml!.trim().isNotEmpty) {
      final p = await SharedPreferences.getInstance();
      await p.setString('kinh_hotpatch_runner_html', patch.runnerHtml!);
    }
    await _hotUpdateService.markApplied(patch.patchVersion);
  }

  static final List<BentoItem> _items = [
    const BentoItem(
      id: 'search',
      title: 'Tìm kiếm / Trình duyệt',
      icon: Icons.search_rounded,
      size: BentoSize.wide,
      accentColor: Color(0xFF6C8CFF),
    ),
    const BentoItem(
      id: 'ai_builder',
      title: 'AI Builder',
      icon: Icons.auto_awesome,
      size: BentoSize.wide,
      accentColor: Color(0xFFB388FF),
    ),
    const BentoItem(
      id: 'weather',
      title: 'Thời tiết',
      icon: Icons.wb_cloudy_rounded,
      size: BentoSize.small,
    ),
    const BentoItem(
      id: 'wifi',
      title: 'Tốc độ Wi-Fi',
      icon: Icons.wifi_rounded,
      size: BentoSize.small,
    ),
    const BentoItem(
      id: 'notes',
      title: 'Ghi chú',
      icon: Icons.sticky_note_2_rounded,
      size: BentoSize.tall,
      accentColor: Color(0xFFFFC46C),
    ),
    const BentoItem(
      id: 'privacy',
      title: 'Nhật ký bảo mật',
      icon: Icons.shield_rounded,
      size: BentoSize.small,
      accentColor: Color(0xFF6CFFA8),
    ),
    const BentoItem(
      id: 'add_app',
      title: '+ Thêm App',
      icon: Icons.add_circle_outline_rounded,
      size: BentoSize.small,
    ),
  ];

  void _onItemTap(BuildContext context, BentoItem item) {
    if (item.id == 'search') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const BrowserScreen()),
      );
      return;
    }
    if (item.id == 'ai_builder') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AiBuilderScreen()),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.title} — sẽ hoạt động ở bước tiếp theo'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            final crossAxisCount = isWide ? 4 : 2;

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        const Icon(Icons.home_rounded,
                            color: Color(0xFF6C8CFF)),
                        const SizedBox(width: 8),
                        const Text(
                          'Kính',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.system_update_alt_rounded,
                              color: Colors.white70),
                          tooltip: 'Kiểm tra cập nhật',
                          onPressed: () => _checkUpdate(force: true),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_dashboardNotice != null)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C8CFF).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF6C8CFF).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.campaign_rounded,
                                size: 18, color: Color(0xFF6C8CFF)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _dashboardNotice!,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  size: 16, color: Colors.white54),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () =>
                                  setState(() => _dashboardNotice = null),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Nút mở trình duyệt nhanh
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BrowserScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.language_rounded),
                      label: const Text('Mở trình duyệt'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6C8CFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                      ),
                    ),
                  ),
                ),
                // Bento grid
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = _items[index];
                        return BentoCard(
                          item: item,
                          onTap: () => _onItemTap(context, item),
                        );
                      },
                      childCount: _items.length,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
