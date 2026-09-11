import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity_event.dart';
import '../models/history_entry.dart';

/// Visual Activity Log — sự kiện duyệt web (minh bạch).
/// Sự kiện ephemeral (incognito) chỉ nằm RAM, không ghi đĩa.
class ActivityLogService {
  static const _key = 'kinh_activity_log_v1';
  static const _maxPersisted = 300;
  static const _maxRam = 500;

  final List<ActivityEvent> _items = [];
  List<ActivityEvent> get items => List.unmodifiable(_items);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    _items.clear();
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      for (final e in list) {
        _items.add(
            ActivityEvent.fromJson(Map<String, dynamic>.from(e as Map)));
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    final toSave =
        _items.where((e) => !e.ephemeral).take(_maxPersisted).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(toSave.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> log({
    required ActivityKind kind,
    required String message,
    String? url,
    bool ephemeral = false,
  }) async {
    final domain = url != null ? HistoryEntry.domainOf(url) : null;
    _items.insert(
      0,
      ActivityEvent(
        kind: kind,
        message: message,
        url: url,
        domain: domain,
        ephemeral: ephemeral,
      ),
    );
    while (_items.length > _maxRam) {
      _items.removeLast();
    }
    if (!ephemeral) await _persist();
  }

  Future<void> clearAll() async {
    _items.clear();
    await _persist();
  }

  Future<void> clearPersistedOnly() async {
    _items.removeWhere((e) => !e.ephemeral);
    await _persist();
  }
}
