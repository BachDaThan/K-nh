import 'package:shared_preferences/shared_preferences.dart';

/// Chế độ máy yếu — hành vi cụ thể, không “magic mọi chip”.
class PerformanceService {
  static const _key = 'kinh_low_end_mode';
  bool lowEndMode = false;

  /// Giới hạn tab trình duyệt khi low-end.
  int get maxBrowserTabs => lowEndMode ? 3 : 20;

  /// Tắt animation radar / glow dashboard.
  bool get reduceMotion => lowEndMode;

  /// Gợi ý bật reader cho trang dài (UI có thể tôn trọng).
  bool get preferReaderOnLongPages => lowEndMode;

  String get descriptionVi => lowEndMode
      ? 'Đang bật: tối đa $maxBrowserTabs tab · giảm animation · ưu tiên nhẹ.'
      : 'Tắt: đủ hiệu ứng · nhiều tab hơn.';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    lowEndMode = p.getBool(_key) ?? false;
  }

  Future<void> setLowEnd(bool v) async {
    lowEndMode = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, v);
  }
}

final performanceService = PerformanceService();
