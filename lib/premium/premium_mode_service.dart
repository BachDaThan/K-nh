import 'package:shared_preferences/shared_preferences.dart';

enum PremiumMeshMode {
  /// Firebase + optional BLE light scan
  auto,
  /// Ưu tiên mesh native / UI tối giản
  survival,
}

class PremiumModeService {
  static const _key = 'kinh_premium_mesh_mode';
  PremiumMeshMode mode = PremiumMeshMode.auto;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(_key);
    mode = v == 'survival' ? PremiumMeshMode.survival : PremiumMeshMode.auto;
  }

  Future<void> setMode(PremiumMeshMode m) async {
    mode = m;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, m.name);
  }
}

final premiumModeService = PremiumModeService();
