import 'package:flutter/material.dart';
import '../models/bento_item.dart';
import '../widgets/bento_card.dart';

/// Trang Dashboard trung tâm — tab cố định đầu tiên.
/// Bước 1: hiển thị lưới Bento Grid tĩnh, responsive 2 cột (mobile)
/// / 4 cột (desktop/tablet), theo đúng thiết kế trong hồ sơ dự án.
///
/// Các bước sau sẽ thêm: drag & drop sắp xếp lại ô, App Launcher quét
/// app hệ thống, widget thời tiết/wifi/ghi chú thật, thanh Tab trình
/// duyệt phía trên, Sidebar bên trái.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Danh sách mẫu — sẽ thay bằng dữ liệu thật + có thể tùy biến ở bước sau.
  static final List<BentoItem> _items = [
    const BentoItem(
      id: 'search',
      title: 'Tìm kiếm',
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Icon(Icons.home_rounded,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text(
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
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${item.title} — sẽ hoạt động ở bước tiếp theo'),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
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
