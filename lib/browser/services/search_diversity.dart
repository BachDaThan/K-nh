import 'package:shared_preferences/shared_preferences.dart';

/// "Độ sáng tạo Search" (Search Diversity Index).
///
/// 0.0 → chỉ nguồn chính thống (.gov / .edu / báo lớn / Wikipedia)
/// 0.5 → tiêu chuẩn
/// >1.0 → mở rộng trang ngách / blog / diễn đàn
///
/// Cách áp dụng: chỉnh query trước khi đưa vào engine tìm kiếm
/// (thêm/ bớt site: operator hoặc chuyển search engine).
class SearchDiversityService {
  static const _key = 'search_diversity_index';
  double _index = 0.5;

  double get index => _index;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _index = prefs.getDouble(_key) ?? 0.5;
  }

  Future<void> setIndex(double value) async {
    _index = value.clamp(0.0, 2.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, _index);
  }

  /// Biến đổi từ khóa thô thành query thực tế gửi cho search engine.
  String transformQuery(String raw) {
    final q = raw.trim();
    if (q.isEmpty) return q;

    // Đã là URL thì không đụng.
    if (q.contains('://') || q.startsWith('www.')) return q;

    if (_index <= 0.15) {
      // Chỉ nguồn chính thống
      return '$q (site:.gov OR site:.edu OR site:wikipedia.org OR site:bbc.com OR site:reuters.com OR site:nytimes.com)';
    } else if (_index <= 0.4) {
      return '$q (site:.gov OR site:.edu OR site:wikipedia.org OR site:*.edu.*)';
    } else if (_index <= 0.7) {
      // Tiêu chuẩn — không thêm filter
      return q;
    } else if (_index <= 1.2) {
      // Mở rộng nhẹ
      return '$q (blog OR forum OR "personal site" OR medium.com OR reddit.com OR stackoverflow.com)';
    } else {
      // Rất đa dạng / ngách
      return '$q (site:*.blog OR site:*.xyz OR site:*.io OR inurl:forum OR inurl:board OR "obscure" OR niche)';
    }
  }

  String get label {
    if (_index <= 0.2) return 'Chính thống';
    if (_index <= 0.6) return 'Tiêu chuẩn';
    if (_index <= 1.1) return 'Đa dạng';
    return 'Ngách / mở rộng';
  }
}
