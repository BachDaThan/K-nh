import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'browser_engine.dart';

/// Implementation dùng System WebView (Chromium) trên Android
/// và WebView2 trên Windows thông qua flutter_inappwebview.
///
/// Đây là engine tạm thời cho Bước 2.
/// Khi GeckoView plugin chín, tạo GeckoBrowserEngine implement cùng
/// [BrowserEngine] và thay thế ở factory — không cần sửa UI/tính năng.
class ChromiumBrowserEngine implements BrowserEngine {
  final Map<String, InAppWebViewController> _controllers = {};
  final Map<String, double> _zoomLevels = {};

  /// Callbacks để UI cập nhật state tab (title, url, progress...).
  void Function(String tabId, String? title)? onTitleChanged;
  void Function(String tabId, String? url)? onUrlChanged;
  void Function(String tabId, double progress)? onProgressChanged;
  void Function(String tabId, bool isLoading)? onLoadingChanged;
  void Function(String tabId, bool canBack, bool canForward)? onNavStateChanged;
  void Function(String tabId, String url, String fileName)? onDownloadStart;

  @override
  Widget buildView({
    required String tabId,
    required VoidCallback onCreated,
  }) {
    return InAppWebView(
      key: ValueKey('webview_$tabId'),
      initialUrlRequest: URLRequest(url: WebUri('about:blank')),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        iframeAllowFullscreen: true,
        supportZoom: true,
        builtInZoomControls: true,
        displayZoomControls: false,
        useOnDownloadStart: true,
        isInspectable: kDebugMode,
        userAgent: null, // dùng default của engine → có thể inspect để xác minh
      ),
      onWebViewCreated: (controller) {
        _controllers[tabId] = controller;
        _zoomLevels[tabId] = 1.0;
        onCreated();
      },
      onLoadStart: (controller, url) {
        onLoadingChanged?.call(tabId, true);
        onUrlChanged?.call(tabId, url?.toString());
        _emitNavState(tabId, controller);
      },
      onLoadStop: (controller, url) async {
        onLoadingChanged?.call(tabId, false);
        onUrlChanged?.call(tabId, url?.toString());
        final title = await controller.getTitle();
        onTitleChanged?.call(tabId, title);
        _emitNavState(tabId, controller);
      },
      onProgressChanged: (controller, progress) {
        onProgressChanged?.call(tabId, progress / 100.0);
      },
      onTitleChanged: (controller, title) {
        onTitleChanged?.call(tabId, title);
      },
      onDownloadStartRequest: (controller, request) {
        final url = request.url.toString();
        final fileName = request.suggestedFilename ??
            url.split('/').last.split('?').first;
        onDownloadStart?.call(tabId, url, fileName);
      },
      shouldOverrideUrlLoading: (controller, action) async {
        // Cho phép điều hướng bình thường; sau này có thể chặn theo DoH/ad-block.
        return NavigationActionPolicy.ALLOW;
      },
    );
  }

  Future<void> _emitNavState(String tabId, InAppWebViewController c) async {
    final back = await c.canGoBack();
    final forward = await c.canGoForward();
    onNavStateChanged?.call(tabId, back, forward);
  }

  InAppWebViewController? _c(String tabId) => _controllers[tabId];

  @override
  Future<void> loadUrl(String tabId, String urlOrQuery) async {
    final c = _c(tabId);
    if (c == null) return;

    String target = urlOrQuery.trim();
    if (target.isEmpty) return;

    // Nếu không phải URL rõ ràng → coi là tìm kiếm Google.
    final looksLikeUrl = target.contains('://') ||
        (target.contains('.') && !target.contains(' '));
    if (!looksLikeUrl) {
      final encoded = Uri.encodeComponent(target);
      target = 'https://www.google.com/search?q=$encoded';
    } else if (!target.contains('://')) {
      target = 'https://$target';
    }

    await c.loadUrl(urlRequest: URLRequest(url: WebUri(target)));
  }

  @override
  Future<void> goBack(String tabId) async {
    final c = _c(tabId);
    if (c != null && await c.canGoBack()) await c.goBack();
  }

  @override
  Future<void> goForward(String tabId) async {
    final c = _c(tabId);
    if (c != null && await c.canGoForward()) await c.goForward();
  }

  @override
  Future<void> reload(String tabId) async {
    await _c(tabId)?.reload();
  }

  @override
  Future<void> stopLoading(String tabId) async {
    await _c(tabId)?.stopLoading();
  }

  @override
  Future<bool> canGoBack(String tabId) async {
    return await _c(tabId)?.canGoBack() ?? false;
  }

  @override
  Future<bool> canGoForward(String tabId) async {
    return await _c(tabId)?.canGoForward() ?? false;
  }

  @override
  Future<void> setZoom(String tabId, double factor) async {
    final c = _c(tabId);
    if (c == null) return;
    final clamped = factor.clamp(0.25, 5.0);
    _zoomLevels[tabId] = clamped;
    // InAppWebView dùng zoomBy relative; đặt về 1 rồi zoomBy.
    await c.zoomBy(zoomFactor: clamped);
  }

  @override
  Future<double> getZoom(String tabId) async {
    return _zoomLevels[tabId] ?? 1.0;
  }

  @override
  Future<String?> getCurrentUrl(String tabId) async {
    final uri = await _c(tabId)?.getUrl();
    return uri?.toString();
  }

  @override
  Future<String?> getTitle(String tabId) async {
    return await _c(tabId)?.getTitle();
  }

  @override
  Future<dynamic> evaluateJavascript(String tabId, String source) async {
    return await _c(tabId)?.evaluateJavascript(source: source);
  }

  @override
  Future<void> clearCookies() async {
    await CookieManager.instance().deleteAllCookies();
  }

  @override
  Future<void> clearCache() async {
    // Xóa cache của tất cả controller đang mở.
    for (final c in _controllers.values) {
      await c.clearCache();
    }
  }

  @override
  Future<void> printToPdf(String tabId) async {
    final c = _c(tabId);
    if (c == null) return;
    // InAppWebView hỗ trợ print trên một số platform.
    try {
      await c.printCurrentPage();
    } catch (_) {
      // Fallback: không hỗ trợ trên platform này.
    }
  }

  @override
  Future<String?> getUserAgent(String tabId) async {
    return await _c(tabId)?.getSettings().then((s) => s?.userAgent);
  }

  @override
  Future<void> disposeTab(String tabId) async {
    _controllers.remove(tabId);
    _zoomLevels.remove(tabId);
  }

  @override
  Future<void> dispose() async {
    _controllers.clear();
    _zoomLevels.clear();
  }
}
