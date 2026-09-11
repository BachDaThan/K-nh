import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Lưu mật khẩu local (không mã hóa mạnh — chỉ phù hợp MVP client-side).
/// Sau này có thể nâng cấp sang flutter_secure_storage / encrypted box.
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
  static const _key = 'passwords_v1';
  final List<SavedCredential> _items = [];

  List<SavedCredential> get items => List.unmodifiable(_items);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    _items.clear();
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      _items.addAll(
        list.map((e) => SavedCredential.fromJson(e as Map<String, dynamic>)),
      );
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(_items.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> save(SavedCredential cred) async {
    _items.removeWhere((c) => c.origin == cred.origin && c.username == cred.username);
    _items.add(cred);
    await _save();
  }

  Future<void> remove(String origin, String username) async {
    _items.removeWhere((c) => c.origin == origin && c.username == username);
    await _save();
  }

  List<SavedCredential> forOrigin(String origin) =>
      _items.where((c) => c.origin == origin).toList();
}
