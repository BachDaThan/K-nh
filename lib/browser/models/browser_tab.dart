import 'package:uuid/uuid.dart';

/// Một tab trình duyệt.
class BrowserTab {
  final String id;
  String title;
  String url;
  bool isLoading;
  double progress; // 0.0 – 1.0
  bool canGoBack;
  bool canGoForward;
  DateTime lastAccessed;
  /// Tab ẩn danh: không ghi lịch sử / activity log ra đĩa.
  final bool isIncognito;

  BrowserTab({
    String? id,
    this.title = 'Tab mới',
    this.url = 'about:blank',
    this.isLoading = false,
    this.progress = 0.0,
    this.canGoBack = false,
    this.canGoForward = false,
    DateTime? lastAccessed,
    this.isIncognito = false,
  })  : id = id ?? const Uuid().v4(),
        lastAccessed = lastAccessed ?? DateTime.now();

  BrowserTab copyWith({
    String? title,
    String? url,
    bool? isLoading,
    double? progress,
    bool? canGoBack,
    bool? canGoForward,
    DateTime? lastAccessed,
    bool? isIncognito,
  }) {
    return BrowserTab(
      id: id,
      title: title ?? this.title,
      url: url ?? this.url,
      isLoading: isLoading ?? this.isLoading,
      progress: progress ?? this.progress,
      canGoBack: canGoBack ?? this.canGoBack,
      canGoForward: canGoForward ?? this.canGoForward,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      isIncognito: isIncognito ?? this.isIncognito,
    );
  }
}
