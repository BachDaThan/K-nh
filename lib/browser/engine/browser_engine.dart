import 'package:flutter/widgets.dart';

/// Trừu tượng hóa nhân trình duyệt.
///
/// **Quyết định kiến trúc (Bước 2):**
/// - Implementation hiện tại: [ChromiumBrowserEngine]
///   (Android = System WebView / Chromium, Windows = WebView2).
/// - Mục tiêu dài hạn: thêm [GeckoBrowserEngine] (GeckoView / Firefox)
///   khi plugin Flutter cho GeckoView chín hơn.
/// - Toàn bộ UI và tính năng (Omnibox, Tab, Bookmark, Download, DoH,
///   Search Diversity, Activity Log...) CHỈ được gọi qua interface này.
///   Không được import trực tiếp flutter_inappwebview / webview_flutter
///   ở bất kỳ file nào ngoài thư mục engine/.
///
/// Lý do tạm thời dùng Chromium:
/// - Plugin GeckoView Flutter hiện là WIP, thiếu nhiều API, APK size lớn,
///   và xung đột với quy tắc "không commit thư mục android/" (GeckoView
///   đòi hỏi chỉnh Gradle + Maven Mozilla + proguard đặc biệt).
abstract class BrowserEngine {
  /// Tạo widget hiển thị nội dung web của tab đang active.
  Widget buildView({
    required String tabId,
    required VoidCallback onCreated,
  });

  /// Load URL hoặc từ khóa tìm kiếm vào tab.
  Future<void> loadUrl(String tabId, String urlOrQuery);

  /// Điều hướng.
  Future<void> goBack(String tabId);
  Future<void> goForward(String tabId);
  Future<void> reload(String tabId);
  Future<void> stopLoading(String tabId);

  /// Trạng thái điều hướng.
  Future<bool> canGoBack(String tabId);
  Future<bool> canGoForward(String tabId);

  /// Zoom (0.25 – 5.0).
  Future<void> setZoom(String tabId, double factor);
  Future<double> getZoom(String tabId);

  /// Lấy URL / title hiện tại của tab.
  Future<String?> getCurrentUrl(String tabId);
  Future<String?> getTitle(String tabId);

  /// JavaScript / inject (dùng cho DoH hint, ad-block, streaming hook...).
  Future<dynamic> evaluateJavascript(String tabId, String source);

  /// Cookie / session (có thể khác nhau giữa Chromium và Gecko).
  Future<void> clearCookies();
  Future<void> clearCache();

  /// In trang hiện tại ra PDF (nếu engine hỗ trợ).
  Future<void> printToPdf(String tabId);

  /// User-Agent (để debug / xác minh engine).
  Future<String?> getUserAgent(String tabId);

  /// Giải phóng tài nguyên khi đóng tab.
  Future<void> disposeTab(String tabId);

  /// Giải phóng toàn bộ engine.
  Future<void> dispose();
}
