import 'dart:typed_data';

import 'package:installed_apps/installed_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Một app đã cài trên máy, đủ thông tin để hiển thị + ghim vào Dashboard.
class InstalledApp {
  final String packageName;
  final String name;
  final Uint8List? icon;

  InstalledApp({
    required this.packageName,
    required this.name,
    this.icon,
  });
}

/// Quét app đã cài trên Android (chỉ Android — Windows không có khái niệm
/// "app đã cài" theo cách này, App Launcher trên Windows để ở Bước 6 sau,
/// dùng registry/Start Menu, phức tạp hơn nên chưa làm).
///
/// Cần quyền QUERY_ALL_PACKAGES trong AndroidManifest (đã thêm qua CI).
/// Đây là quyền "normal" — không cần người dùng bấm đồng ý qua dialog hệ
/// thống, tự động có khi cài app.
class AppLauncherService {
  static const _keyPinned = 'kinh_pinned_apps'; // danh sách packageName đã ghim

  Future<List<InstalledApp>> listInstalledApps() async {
    try {
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: true,
        excludeNonLaunchableApps: true,
        withIcon: true,
      );
      final result = apps
          .map((a) => InstalledApp(
                packageName: a.packageName,
                name: a.name,
                icon: a.icon,
              ))
          .toList();
      result.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return result;
    } catch (_) {
      // Lỗi quyền/thiết bị không hỗ trợ — trả về rỗng, không crash app.
      return [];
    }
  }

  Future<void> openApp(String packageName) async {
    try {
      await InstalledApps.startApp(packageName);
    } catch (_) {
      // Không mở được (app bị gỡ, lỗi intent...) — im lặng bỏ qua, UI có
      // thể hiện SnackBar báo lỗi riêng nếu cần.
    }
  }

  Future<List<String>> getPinnedPackageNames() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(_keyPinned) ?? [];
  }

  Future<void> pin(String packageName) async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_keyPinned) ?? [];
    if (!list.contains(packageName)) {
      list.add(packageName);
      await p.setStringList(_keyPinned, list);
    }
  }

  Future<void> unpin(String packageName) async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_keyPinned) ?? [];
    list.remove(packageName);
    await p.setStringList(_keyPinned, list);
  }
}
