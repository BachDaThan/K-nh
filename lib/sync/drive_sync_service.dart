import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'local_backup_service.dart';

/// Google Drive sync — đọc file JSON backup user đã upload lên Drive.
///
/// - Thủ công: bấm "Đồng bộ ngay"
/// - Tự động: bật [autoSync], app tự tải file đã chọn khi mở Dashboard
/// - Lưu [fileId] + tên file; có thể đổi file bất kỳ lúc nào
///
/// Cần OAuth client trong Google Cloud (xem DRIVE_SETUP.md).
/// Android: package `com.bachdathan.kinh` + SHA-1 keystore release.
class DriveSyncService {
  static const _kAuto = 'kinh_drive_auto_sync';
  static const _kFileId = 'kinh_drive_file_id';
  static const _kFileName = 'kinh_drive_file_name';
  static const _kLastSync = 'kinh_drive_last_sync_ms';
  static const _kClientId = 'kinh_drive_oauth_client_id';

  static const _driveScope =
      'https://www.googleapis.com/auth/drive.readonly';

  final _backup = LocalBackupService();

  GoogleSignIn? _gsi;
  GoogleSignInAccount? account;

  bool autoSync = false;
  String? fileId;
  String? fileName;
  int? lastSyncMs;

  bool get isSignedIn => account != null;
  bool get hasLinkedFile => fileId != null && fileId!.isNotEmpty;

  Future<void> loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    autoSync = p.getBool(_kAuto) ?? false;
    fileId = p.getString(_kFileId);
    fileName = p.getString(_kFileName);
    lastSyncMs = p.getInt(_kLastSync);
  }

  Future<void> setAutoSync(bool v) async {
    autoSync = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kAuto, v);
  }

  Future<void> setLinkedFile({required String id, required String name}) async {
    fileId = id;
    fileName = name;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kFileId, id);
    await p.setString(_kFileName, name);
  }

  Future<void> clearLinkedFile() async {
    fileId = null;
    fileName = null;
    final p = await SharedPreferences.getInstance();
    await p.remove(_kFileId);
    await p.remove(_kFileName);
  }

  Future<String?> getSavedClientId() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kClientId);
  }

  Future<void> saveClientId(String id) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kClientId, id.trim());
    _gsi = null; // recreate on next sign-in
  }

  GoogleSignIn _client({String? clientId}) {
    // Android dùng client gắn SHA-1 trong Cloud Console (clientId tùy chọn).
    // iOS/Web cần clientId; Windows: google_sign_in hạn chế — báo user.
    return GoogleSignIn(
      scopes: [_driveScope, 'email'],
      clientId: (clientId != null && clientId.isNotEmpty) ? clientId : null,
    );
  }

  Future<bool> get isPlatformSupported async {
    if (kIsWeb) return true;
    return Platform.isAndroid || Platform.isIOS;
  }

  Future<String?> signIn() async {
    if (!await isPlatformSupported) {
      return 'Google Sign-In trên nền tảng này chưa hỗ trợ ổn. '
          'Dùng Backup JSON thủ công (Export/Import) trên Windows.';
    }
    final saved = await getSavedClientId();
    _gsi ??= _client(clientId: saved);
    try {
      account = await _gsi!.signIn();
      if (account == null) return 'Đăng nhập bị hủy';
      return null;
    } catch (e) {
      return 'Đăng nhập lỗi: $e';
    }
  }

  Future<void> signOut() async {
    await _gsi?.signOut();
    account = null;
  }

  Future<Map<String, String>?> _authHeaders() async {
    final a = account ?? await _gsi?.signInSilently();
    account = a;
    if (a == null) return null;
    return a.authHeaders;
  }

  /// Liệt kê file JSON / text trên Drive (tối đa 50).
  Future<List<DriveFileItem>> listCandidateFiles() async {
    final headers = await _authHeaders();
    if (headers == null) throw StateError('Chưa đăng nhập Google');

    final q = Uri.encodeQueryComponent(
      "(mimeType='application/json' or mimeType='text/plain' or name contains '.json') and trashed=false",
    );
    final uri = Uri.parse(
      'https://www.googleapis.com/drive/v3/files'
      '?pageSize=50&fields=files(id,name,modifiedTime,size)'
      '&q=$q&orderBy=modifiedTime desc',
    );
    final res = await http.get(uri, headers: headers).timeout(
          const Duration(seconds: 20),
        );
    if (res.statusCode != 200) {
      throw StateError('Drive list ${res.statusCode}: ${res.body}');
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final files = (j['files'] as List?) ?? [];
    return files
        .map((e) => DriveFileItem(
              id: e['id'] as String,
              name: e['name'] as String? ?? '(no name)',
              modifiedTime: e['modifiedTime'] as String?,
            ))
        .toList();
  }

  /// Tải nội dung file và import qua LocalBackupService.
  Future<String> pullAndImport({String? overrideFileId}) async {
    final id = overrideFileId ?? fileId;
    if (id == null || id.isEmpty) {
      throw StateError('Chưa chọn file trên Drive');
    }
    final headers = await _authHeaders();
    if (headers == null) throw StateError('Chưa đăng nhập Google');

    final uri = Uri.parse(
      'https://www.googleapis.com/drive/v3/files/$id?alt=media',
    );
    final res = await http.get(uri, headers: headers).timeout(
          const Duration(seconds: 30),
        );
    if (res.statusCode != 200) {
      throw StateError('Tải file ${res.statusCode}: ${res.body}');
    }
    final body = res.body;
    final n = await _backup.importJson(body);
    final p = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await p.setInt(_kLastSync, now);
    lastSyncMs = now;
    return 'Đã import $n khóa từ Drive (${fileName ?? id})';
  }

  /// Gọi khi mở app nếu autoSync bật.
  Future<String?> autoPullIfEnabled() async {
    if (!autoSync || !hasLinkedFile) return null;
    if (!await isPlatformSupported) return null;
    try {
      _gsi ??= _client(clientId: await getSavedClientId());
      account = await _gsi!.signInSilently();
      if (account == null) return null; // im lặng nếu chưa session
      return await pullAndImport();
    } catch (_) {
      return null; // auto: không spam lỗi
    }
  }
}

class DriveFileItem {
  final String id;
  final String name;
  final String? modifiedTime;

  DriveFileItem({
    required this.id,
    required this.name,
    this.modifiedTime,
  });
}
