import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../premium/kinh_mesh_channel.dart';

/// Không dùng `permission_handler` (vỡ build Windows / MSVC coroutine).
class MeshPermissions {
  static const _ch = MethodChannel('com.bachdathan.kinh/mesh');

  static Future<String> ensureForMesh() async {
    if (kIsWeb) return 'Web: không dùng mesh BLE';
    if (Platform.isWindows) {
      return 'Windows: mesh BLE không hỗ trợ; dùng LAN nếu cùng mạng.';
    }
    if (!Platform.isAndroid) {
      return 'Nền tảng này không xin quyền BLE trong app.';
    }
    final ok = await kinhMeshChannel.isNativeAvailable;
    if (!ok) {
      return 'APK chưa có native mesh (CI inject). Chỉ LAN. '
          'Xiaomi: sau khi có APK inject, bật quyền Bluetooth/Thiết bị gần thủ công.';
    }
    try {
      await _ch.invokeMethod('requestPermissions');
    } catch (e) {
      return 'Không gọi xin quyền: $e — mở Cài đặt quyền app.';
    }
    return 'Đã xin quyền Bluetooth/Nearby (nếu hệ thống hiện dialog). '
        'Xiaomi: nếu không hiện, Cài đặt → Ứng dụng → Kính → Quyền.';
  }

  static Future<bool> openAppSettingsPage() async {
    if (!Platform.isAndroid) return false;
    try {
      await _ch.invokeMethod('openAppSettings');
      return true;
    } catch (_) {
      return false;
    }
  }
}
