import 'package:shared_preferences/shared_preferences.dart';

/// Tối ưu nhẹ cho máy yếu — không magic “mọi phần cứng”, chỉ giảm hiệu ứng.
class PerformanceService {
  static const _key = 'kinh_low_end_mode';
  bool lowEndMode = false;

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
