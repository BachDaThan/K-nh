import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'browser_engine.dart';

/// Implementation dùng System WebView (Chromium) trên Android
/// và WebView2 trên Windows (qua webview_flutter + webview_win_floating).
///
/// Thay thế flutter_inappwebview vì package đó lỗi build trên
/// Flutter 3.47 + AGP mới (proguard) và MSVC mới (experimental coroutine).
class ChromiumBrowserEngine implements BrowserEngine {
  final Map<String, WebViewController> _controllers = {};
  final Map<String, double> _zoomLevels = {};
  static bool _platformRegistered = false;

  void Function(String tabId, String? title)? onTitleChanged;
  void Function(String tabId, String? url)? onUrlChanged;
  void Function(String tabId, double progress)? onProgressChanged;
  void Function(String tabId, bool isLoading)? onLoadingChanged;
  void Function(String tabId, bool canBack, bool canForward)? onNavStateChanged;
  void Function(String tabId, String url, String fileName)? onDownloadStart;

  void _ensurePlatform() {
    if (_platformRegistered) return;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      try {
        // ignore: depend_on_referenced_packages
        // Đăng ký Windows WebView2 — import động qua conditional không ổn định
        // trên mọi SDK; webview_win_floating tự register qua pubspec plugin.
      } catch (_) {}
    }
    _platformRegistered = true;
  }

  WebViewController _createController(String tabId) {
    _ensurePlatform();
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF121212))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            onLoadingChanged?.call(tabId, true);
            onUrlChanged?.call(tabId, url);
            onProgressChanged?.call(tabId, 0.1);
          },
          onProgress: (progress) {
            onProgressChanged?.call(tabId, progress / 100.0);
          },
          onPageFinished: (url) async {
            onLoadingChanged?.call(tabId, false);
            onUrlChanged?.call(tabId, url);
            onProgressChanged?.call(tabId, 1.0);
            final c = _controllers[tabId];
            if (c != null) {
              final title = await c.getTitle();
              onTitleChanged?.call(tabId, title);
              final back = await c.canGoBack();
              final forward = await c.canGoForward();
              onNavStateChanged?.call(tabId, back, forward);
            }
          },
          onWebResourceError: (error) {
            onLoadingChanged?.call(tabId, false);
          },
          onNavigationRequest: (request) {
            return NavigationDecision.navigate;
          },
        ),
      );

    _controllers[tabId] = controller;
    _zoomLevels[tabId] = 1.0;
    return controller;
  }

  @override
  Widget buildView({
    required String tabId,
    required VoidCallback onCreated,
  }) {
    final existing = _controllers[tabId];
    final controller = existing ?? _createController(tabId);

    WidgetsBinding.instance.addPostFrameCallback((_) => onCreated());

    return WebViewWidget(
      key: ValueKey('webview_$tabId'),
      controller: controller,
    );
  }

  WebViewController? _c(String tabId) => _controllers[tabId];

  @override
  Future<void> loadUrl(String tabId, String urlOrQuery) async {
    var c = _c(tabId);
    c ??= _createController(tabId);

    String target = urlOrQuery.trim();
    if (target.isEmpty) return;

    final looksLikeUrl = target.contains('://') ||
        (target.contains('.') && !target.contains(' '));
    if (!looksLikeUrl) {
      final encoded = Uri.encodeComponent(target);
      target = 'https://www.google.com/search?q=$encoded';
    } else if (!target.contains('://')) {
      target = 'https://$target';
    }

    await c.loadRequest(Uri.parse(target));
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
    try {
      await _c(tabId)?.runJavaScript('window.stop();');
    } catch (_) {}
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
    try {
      await c.runJavaScript('document.body.style.zoom = "$clamped";');
    } catch (_) {}
  }

  @override
  Future<double> getZoom(String tabId) async {
    return _zoomLevels[tabId] ?? 1.0;
  }

  @override
  Future<String?> getCurrentUrl(String tabId) async {
    return await _c(tabId)?.currentUrl();
  }

  @override
  Future<String?> getTitle(String tabId) async {
    return await _c(tabId)?.getTitle();
  }

  @override
  Future<dynamic> evaluateJavascript(String tabId, String source) async {
    try {
      return await _c(tabId)?.runJavaScriptReturningResult(source);
    } catch (_) {
      await _c(tabId)?.runJavaScript(source);
      return null;
    }
  }

  @override
  Future<void> clearCookies() async {
    final cookieManager = WebViewCookieManager();
    await cookieManager.clearCookies();
  }

  @override
  Future<void> clearCache() async {
    for (final c in _controllers.values) {
      try {
        await c.clearCache();
        await c.clearLocalStorage();
      } catch (_) {}
    }
  }

  @override
  Future<void> printToPdf(String tabId) async {
    try {
      await _c(tabId)?.runJavaScript('window.print();');
    } catch (_) {}
  }

  @override
  Future<String?> getUserAgent(String tabId) async {
    try {
      final result = await _c(tabId)
          ?.runJavaScriptReturningResult('navigator.userAgent');
      return result?.toString();
    } catch (_) {
      return null;
    }
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
