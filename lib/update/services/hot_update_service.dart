import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Nội dung một Hot Patch đã được verify chữ ký hợp lệ.
class HotPatch {
  final int patchVersion; // số tăng dần, không phải semver app
  final String? runnerHtml; // HTML mới cho AI Builder code runner (optional)
  final String? dashboardNotice; // text thông báo hiện trên Dashboard (optional)

  HotPatch({
    required this.patchVersion,
    this.runnerHtml,
    this.dashboardNotice,
  });
}

/// Hot Update: tải + verify + áp dụng bản vá nội dung (HTML/JS/text cấu
/// hình) KHÔNG cần build lại APK/EXE, KHÔNG cần người dùng cài lại.
///
/// AN TOÀN LÀ TỐI QUAN TRỌNG Ở ĐÂY: vì hot patch áp dụng ngầm, không qua
/// bước "người dùng bấm cài" như Binary Update, nó BẮT BUỘC phải được ký
/// bằng Ed25519 và verify bằng public key nhúng cứng trong app. Nếu chữ ký
/// sai hoặc thiếu, patch bị từ chối HOÀN TOÀN — không áp dụng một phần,
/// không "tin tạm".
///
/// Quy trình phát hành 1 bản hot patch (làm THỦ CÔNG, KHÔNG qua CI):
/// 1. Sửa nội dung cần vá (vd runner HTML mới).
/// 2. Chạy script ký (xem `tool/sign_hotpatch.py`, không có trong app) với
///    private key giữ riêng (KHÔNG BAO GIỜ đưa vào repo/GitHub Secrets).
/// 3. Script xuất ra `hotpatch.json` đã có field `signature`.
/// 4. Tự tay commit + push `hotpatch.json` lên repo.
class HotUpdateService {
  static const _hotpatchUrl =
      'https://cdn.jsdelivr.net/gh/BachDaThan/K-nh@main/hotpatch.json';

  /// Public key Ed25519 nhúng cứng — an toàn khi công khai, dùng để verify
  /// chữ ký của mọi hot patch. Khớp với private key giữ riêng offline.
  static const _publicKeyBase64 =
      'TN+MSZfj/fVPLjTreVckCDKoCxizIB4CWUcH59f1wcA=';

  static const _keyAppliedVersion = 'kinh_hotpatch_applied_version';

  /// Tải, verify chữ ký, và trả về patch nếu hợp lệ VÀ mới hơn bản đã áp
  /// dụng trước đó. Trả về null nếu: lỗi mạng, chữ ký sai, hoặc không có
  /// gì mới.
  Future<HotPatch?> fetchAndVerify({bool force = false}) async {
    try {
      final url = force
          ? '$_hotpatchUrl?t=${DateTime.now().millisecondsSinceEpoch}'
          : _hotpatchUrl;

      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body) as Map<String, dynamic>;

      final signatureB64 = json['signature'] as String?;
      if (signatureB64 == null || signatureB64.isEmpty) {
        // Không có chữ ký — TỪ CHỐI hoàn toàn, không có ngoại lệ.
        return null;
      }

      // QUAN TRỌNG: không tái tạo JSON string để verify (thứ tự key sau
      // khi decode JSON không đảm bảo giống thứ tự lúc ký, chữ ký sẽ fail
      // ngẫu nhiên). Thay vào đó, dựng một chuỗi "canonical" có cấu trúc
      // cố định — PHẢI khớp chính xác với cách tool/sign_hotpatch.py xây
      // dựng payload trước khi ký.
      final patchVersion = (json['patch_version'] as num?)?.toInt() ?? 0;
      final runnerHtml = json['runner_html'] as String?;
      final dashboardNotice = json['dashboard_notice'] as String?;

      final canonicalPayload = _buildCanonicalPayload(
        patchVersion: patchVersion,
        runnerHtml: runnerHtml,
        dashboardNotice: dashboardNotice,
      );
      final payloadBytes = utf8.encode(canonicalPayload);

      final isValid = await _verifySignature(payloadBytes, signatureB64);
      if (!isValid) {
        // Chữ ký sai — có thể bị giả mạo hoặc payload bị sửa sau khi ký.
        // TỪ CHỐI hoàn toàn, không áp dụng bất kỳ phần nào.
        return null;
      }

      final appliedVersion = (await SharedPreferences.getInstance())
              .getInt(_keyAppliedVersion) ??
          0;
      if (patchVersion <= appliedVersion && !force) return null;

      return HotPatch(
        patchVersion: patchVersion,
        runnerHtml: runnerHtml,
        dashboardNotice: dashboardNotice,
      );
    } catch (_) {
      // Lỗi mạng/parse/verify — im lặng bỏ qua, không làm phiền người dùng
      // và tuyệt đối không áp dụng patch khi có bất kỳ nghi ngờ nào.
      return null;
    }
  }

  /// Chuỗi "canonical" cố định dùng để ký/verify — PHẢI khớp chính xác
  /// với cách `tool/sign_hotpatch.py` xây dựng payload trước khi ký.
  /// Field vắng mặt (null) được biểu diễn bằng chuỗi rỗng, không phải
  /// "null" hay bị lược bỏ, để tránh mơ hồ giữa "không có" và "rỗng".
  String _buildCanonicalPayload({
    required int patchVersion,
    String? runnerHtml,
    String? dashboardNotice,
  }) {
    final parts = [
      'patch_version=$patchVersion',
      'runner_html=${runnerHtml ?? ''}',
      'dashboard_notice=${dashboardNotice ?? ''}',
    ];
    return parts.join('\n');
  }

  Future<bool> _verifySignature(
    List<int> payloadBytes,
    String signatureBase64,
  ) async {
    try {
      final algorithm = Ed25519();
      final publicKeyBytes = base64Decode(_publicKeyBase64);
      final signatureBytes = base64Decode(signatureBase64);

      final publicKey = SimplePublicKey(
        publicKeyBytes,
        type: KeyPairType.ed25519,
      );

      final signature = Signature(signatureBytes, publicKey: publicKey);

      return await algorithm.verify(payloadBytes, signature: signature);
    } catch (_) {
      return false;
    }
  }

  /// Đánh dấu patch đã được áp dụng, để không áp dụng lại lần sau.
  Future<void> markApplied(int patchVersion) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_keyAppliedVersion, patchVersion);
  }
}
