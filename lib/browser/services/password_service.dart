import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lưu thông tin đăng nhập cục bộ trong secure storage của hệ điều hành.
///
/// Dữ liệu của phiên bản cũ từng nằm trong SharedPreferences dạng plaintext;
/// [load] sẽ tự chuyển sang secure storage rồi xóa bản cũ.
class SavedCredential {
  final String origin;
  final String username;
  final String password;
  final DateTime updatedAt;

  SavedCredential({
    required this.origin,
    required this.username,
    required this.password,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'origin': origin,
        'username': username,
        'password': password,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory SavedCredential.fromJson(Map<String, dynamic> json) =>
      SavedCredential(
        origin: json['origin'] as String,
        username: json['username'] as String,
        password: json['password'] as String,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

class PasswordService {
  static const _legacyKey = 'passwords_v1';
  static const _secureKey = 'kinh_saved_passwords_v2';
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final List<SavedCredential> _items = [];

  List<SavedCredential> get items => List.unmodifiable(_items);

  Future<void> load() async {
    _items.clear();
    final secureRaw = await _secureStorage.read(key: _secureKey);
    if (secureRaw != null && secureRaw.isNotEmpty) {
      _decodeInto(secureRaw);
      return;
    }

    // Migration từ bản cũ: đọc một lần từ SharedPreferences rồi xóa ngay.
    final prefs = await SharedPreferences.getInstance();
    final legacyRaw = prefs.getString(_legacyKey);
    if (legacyRaw == null || legacyRaw.isEmpty) return;

    _decodeInto(legacyRaw);
    if (_items.isNotEmpty) {
      await _save();
    }
    await prefs.remove(_legacyKey);
  }

  void _decodeInto(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      for (final value in decoded) {
        if (value is! Map) continue;
        try {
          _items.add(SavedCredential.fromJson(
            Map<String, dynamic>.from(value),
          ));
        } catch (_) {
          // Bỏ qua riêng credential hỏng thay vì làm hỏng toàn bộ app.
        }
      }
    } catch (_) {
      // Dữ liệu local có thể hỏng sau crash hoặc sau nâng cấp phiên bản.
    }
  }

  Future<void> _save() async {
    await _secureStorage.write(
      key: _secureKey,
      value: jsonEncode(_items.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> save(SavedCredential cred) async {
    _items.removeWhere(
      (c) => c.origin == cred.origin && c.username == cred.username,
    );
    _items.add(cred);
    await _save();
  }

  Future<void> remove(String origin, String username) async {
    _items.removeWhere(
      (c) => c.origin == origin && c.username == username,
    );
    await _save();
  }

  Future<void> removeAll() async {
    _items.clear();
    await _secureStorage.delete(key: _secureKey);
  }

  List<SavedCredential> forOrigin(String origin) =>
      _items.where((c) => c.origin == origin).toList();
}
