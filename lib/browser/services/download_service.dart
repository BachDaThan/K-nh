import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/download_item.dart';

/// Download Manager đơn giản (Pause/Resume UI + state).
/// Implementation thật sự tải file sẽ dùng InAppWebView download callback
/// hoặc package download riêng; state được giữ ở đây.
class DownloadService {
  static const _key = 'downloads_v1';
  final List<DownloadItem> _items = [];

  List<DownloadItem> get items => List.unmodifiable(_items);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    _items.clear();
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      _items.addAll(
        list.map((e) => DownloadItem.fromJson(e as Map<String, dynamic>)),
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

  Future<DownloadItem> enqueue(String url, String fileName) async {
    final item = DownloadItem(url: url, fileName: fileName);
    _items.insert(0, item);
    await _save();
    return item;
  }

  Future<void> update(DownloadItem item) async {
    final idx = _items.indexWhere((e) => e.id == item.id);
    if (idx >= 0) {
      _items[idx] = item;
      await _save();
    }
  }

  Future<void> pause(String id) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx >= 0 && _items[idx].status == DownloadStatus.downloading) {
      _items[idx].status = DownloadStatus.paused;
      await _save();
    }
  }

  Future<void> resume(String id) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx >= 0 && _items[idx].status == DownloadStatus.paused) {
      _items[idx].status = DownloadStatus.downloading;
      await _save();
    }
  }

  Future<void> cancel(String id) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      _items[idx].status = DownloadStatus.cancelled;
      await _save();
    }
  }

  Future<void> remove(String id) async {
    _items.removeWhere((e) => e.id == id);
    await _save();
  }
}
