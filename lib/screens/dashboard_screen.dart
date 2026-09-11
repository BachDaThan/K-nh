import 'package:flutter/material.dart';
import '../models/bento_item.dart';
import '../widgets/bento_card.dart';
import '../browser/screens/browser_screen.dart';

/// Trang Dashboard trung tâm — tab cố định đầu tiên.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static final List<BentoItem> _items = [
    const BentoItem(
      id: 'search',
      title: 'Tìm kiếm / Trình duyệt',
      icon: Icons.search_rounded,
      size: BentoSize.wide,
      accentColor: Color(0xFF6C8CFF),
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
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Icon(Icons.home_rounded, color: Color(0xFF6C8CFF)),
                        SizedBox(width: 8),
                        Text(
                          'Kính',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
