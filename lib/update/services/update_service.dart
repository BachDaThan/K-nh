import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kết quả kiểm tra cập nhật.
class UpdateInfo {
  final String latestVersion; // vd "0.5.0"
  final String currentVersion; // vd "0.4.0"
  final String releaseNotesUrl; // link trang Release trên GitHub
  final String apkDownloadUrl; // link tải trực tiếp Kinh.apk
  final String exeDownloadUrl; // link tải trực tiếp Kinh-Windows.zip
  final String? body; // changelog (nếu có)

  UpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.releaseNotesUrl,
    required this.apkDownloadUrl,
    required this.exeDownloadUrl,
    this.body,
  });

  /// So sánh semver đơn giản (bỏ qua build number sau dấu +).
  bool get hasUpdate => _compareVersions(latestVersion, currentVersion) > 0;

  static int _compareVersions(String a, String b) {
    List<int> parse(String v) => v
        .split('+')
        .first
        .split('.')
        .map((s) => int.tryParse(s) ?? 0)
        .toList();
    final pa = parse(a);
    final pb = parse(b);
    for (var i = 0; i < 3; i++) {
      final va = i < pa.length ? pa[i] : 0;
      final vb = i < pb.length ? pb[i] : 0;
      if (va != vb) return va.compareTo(vb);
    }
    return 0;
  }
}

/// Kiểm tra & thông báo bản cập nhật mới qua file `version.json` tĩnh trong
/// repo, đọc qua jsDelivr CDN (KHÔNG gọi GitHub REST API — tránh giới hạn
/// 60 request/giờ của api.github.com; jsDelivr không giới hạn request và
/// miễn phí hoàn toàn, không cần thêm dịch vụ nào).
///
/// Lưu ý: jsDelivr cache nội dung theo CDN, nên sau khi push version.json
/// mới có thể mất vài phút tới vài giờ để phản ánh — đây là đánh đổi chấp
/// nhận được cho một app cá nhân, không cần tức thời.
///
/// Nguyên tắc (đã thống nhất trong hồ sơ thiết kế gốc):
/// - KHÔNG silent-install — chỉ thông báo + link tải, người dùng tự bấm cài.
/// - Nếu đang dùng dữ liệu di động (3G/4G), hoãn check để tiết kiệm lưu lượng.
/// - Không check quá thường xuyên — mặc định tối đa 1 lần / 6 giờ, trừ khi
///   người dùng chủ động bấm "Kiểm tra ngay" trong Settings.
class UpdateService {
  static const _versionJsonUrl =
      'https://cdn.jsdelivr.net/gh/BachDaThan/K-nh@main/version.json';
  static const _releasesPageUrl =
      'https://github.com/BachDaThan/K-nh/releases';
  static const _keyLastCheck = 'kinh_update_last_check_ms';
  static const _minCheckIntervalMs = 6 * 60 * 60 * 1000; // 6 giờ

  /// Kiểm tra bản cập nhật mới.
  ///
  /// [force] = true bỏ qua giới hạn 6h và bỏ qua điều kiện Wi-Fi (dùng khi
  /// người dùng chủ động bấm "Kiểm tra ngay").
  Future<UpdateInfo?> check({bool force = false}) async {
    if (!force) {
      final onWifi = await _isOnWifi();
      if (!onWifi) return null; // hoãn nếu đang dùng data di động

      final p = await SharedPreferences.getInstance();
      final last = p.getInt(_keyLastCheck) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - last < _minCheckIntervalMs) return null;
    }

    try {
      // Query string chống cache CDN quá lâu khi force-check.
      final url = force
          ? '$_versionJsonUrl?_=${DateTime.now().millisecondsSinceEpoch}'
          : _versionJsonUrl;

      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final latestVersion = (json['version'] as String?) ?? '0.0.0';
      final apkUrl = (json['apk_url'] as String?) ?? '';
      final exeUrl = (json['exe_url'] as String?) ?? '';
      final changelog = json['changelog'] as String?;

      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;

      final p = await SharedPreferences.getInstance();
      await p.setInt(
          _keyLastCheck, DateTime.now().millisecondsSinceEpoch);

      return UpdateInfo(
        latestVersion: latestVersion,
        currentVersion: currentVersion,
        releaseNotesUrl: _releasesPageUrl,
        apkDownloadUrl: apkUrl,
        exeDownloadUrl: exeUrl,
        body: changelog,
      );
    } catch (_) {
      // Lỗi mạng/parse — im lặng bỏ qua, không làm phiền người dùng.
      return null;
    }
  }

  Future<bool> _isOnWifi() async {
    try {
      final result = await Connectivity().checkConnectivity();
      // connectivity_plus >=6.0 trả về List<ConnectivityResult>
      if (result is List<ConnectivityResult>) {
        return result.contains(ConnectivityResult.wifi) ||
            result.contains(ConnectivityResult.ethernet);
      }
      return false;
    } catch (_) {
      // Không xác định được — mặc định coi như KHÔNG phải Wi-Fi để an toàn
      // (tránh tốn data người dùng nếu detect sai).
      return false;
    }
  }

  /// URL tải phù hợp với nền tảng hiện tại.
  String downloadUrlFor(UpdateInfo info) {
    if (Platform.isWindows) return info.exeDownloadUrl;
    return info.apkDownloadUrl;
  }
}
