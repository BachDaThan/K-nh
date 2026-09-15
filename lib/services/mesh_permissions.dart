import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Xin quyền cho mesh offline (BLE / Nearby / Location trên máy cũ).
/// Xiaomi/MIUI: sau khi app xin, user có thể vẫn phải bật tay trong Cài đặt.
class MeshPermissions {
  /// Trả về mô tả ngắn kết quả (để hiện SnackBar).
  static Future<String> ensureForMesh() async {
    if (kIsWeb || !Platform.isAndroid) {
      return 'Không cần xin quyền mesh trên nền tảng này';
    }

    final need = <Permission>[
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.nearbyWifiDevices,
      Permission.locationWhenInUse, // Android < 12 / một số OEM
      Permission.microphone, // gọi 1-hop
    ];

    final statuses = await need.request();

    final denied = <String>[];
    final permanent = <String>[];

    void check(Permission p, String label) {
      final s = statuses[p];
      if (s == null) return;
      if (s.isPermanentlyDenied) {
        permanent.add(label);
      } else if (s.isDenied || s.isRestricted) {
        denied.add(label);
      }
    }

    check(Permission.bluetoothScan, 'Bluetooth quét');
    check(Permission.bluetoothConnect, 'Bluetooth kết nối');
    check(Permission.bluetoothAdvertise, 'Bluetooth phát');
    check(Permission.nearbyWifiDevices, 'Thiết bị gần / Wi‑Fi');
    check(Permission.locationWhenInUse, 'Vị trí (máy cũ / MIUI)');
    check(Permission.microphone, 'Micro');

    if (permanent.isNotEmpty) {
      return 'Quyền bị từ chối vĩnh viễn: ${permanent.join(", ")}. '
          'Mở Cài đặt ứng dụng → Quyền (Xiaomi: còn xem Quyền khác / Quyền đặc biệt).';
    }
    if (denied.isNotEmpty) {
      return 'Chưa cấp: ${denied.join(", ")}. Bấm Quét lại hoặc mở Cài đặt quyền.';
    }
    return 'Đã xin quyền mesh (Bluetooth / thiết bị gần). '
        'Xiaomi: nếu vẫn không quét được, vào Cài đặt → Ứng dụng → Kính → '
        'Quyền → bật Thiết bị gần / Bluetooth thủ công trên CẢ HAI máy.';
  }

  static Future<bool> openAppSettingsPage() => openAppSettings();
}
