import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import 'browser_engine.dart';
import '../services/search_engine_service.dart';

/// Chromium / System WebView (Android) + WebView2 (Windows).
///
/// Fix load URL: hàng đợi [_pendingUrl] — nếu gọi loadUrl trước khi
/// WebViewWidget mount, URL được giữ và load ngay khi view sẵn sàng.
class ChromiumBrowserEngine implements BrowserEngine {
  final Map<String, WebViewController> _controllers = {};
  final Map<String, double> _zoomLevels = {};
  final Map<String, String> _pendingUrl = {};
  final Set<String> _mounted = {};

  void Function(String tabId, String? title)? onTitleChanged;
  void Function(String tabId, String? url)? onUrlChanged;
  void Function(String tabId, double progress)? onProgressChanged;
  void Function(String tabId, bool isLoading)? onLoadingChanged;
  void Function(String tabId, bool canBack, bool canForward)? onNavStateChanged;
  void Function(String tabId, String url, String fileName)? onDownloadStart;

  WebViewController _createController(String tabId) {
    late final WebViewController controller;
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF1A1A1A))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            onLoadingChanged?.call(tabId, true);
            onUrlChanged?.call(tabId, url);
            onProgressChanged?.call(tabId, 0.05);
          },
          onProgress: (progress) {
            onProgressChanged?.call(tabId, progress / 100.0);
          },
          onPageFinished: (url) async {
            onLoadingChanged?.call(tabId, false);
            onUrlChanged?.call(tabId, url);
            onProgressChanged?.call(tabId, 1.0);
            try {
              final title = await controller.getTitle();
              onTitleChanged?.call(tabId, title);
              final back = await controller.canGoBack();
              final forward = await controller.canGoForward();
              onNavStateChanged?.call(tabId, back, forward);
            } catch (_) {}
          },
          onWebResourceError: (error) {
            onLoadingChanged?.call(tabId, false);
            debugPrint('WebView error [$tabId]: ${error.errorCode} ${error.description}');
          },
          onNavigationRequest: (request) {
            return NavigationDecision.navigate;
          },
        ),
      );

    // Android: network + cache đúng cách (tránh net::ERR_CACHE_MISS)
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final platform = controller.platform;
      if (platform is AndroidWebViewController) {
        AndroidWebViewController.enableDebugging(true);
        platform.setMediaPlaybackRequiresUserGesture(false);
      }
    }

    _controllers[tabId] = controller;
    _zoomLevels[tabId] = 1.0;
    return controller;
  }

  void ensureController(String tabId) {
    _controllers[tabId] ?? _createController(tabId);
  }

  Future<void> _doLoad(String tabId, String target) async {
    final c = _controllers[tabId];
    if (c == null) return;
    debugPrint('WebView load [$tabId]: $target');
    onLoadingChanged?.call(tabId, true);
    onUrlChanged?.call(tabId, target);
    try {
      // Xóa pending trùng (tránh load 2 lần → ERR_CACHE_MISS trên một số máy)
      _pendingUrl.remove(tabId);
      await c.loadRequest(
        Uri.parse(target),
        headers: const {
          // Ép lấy từ mạng, không only-if-cached
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );
    } catch (e) {
      debugPrint('WebView loadRequest failed: $e');
      onLoadingChanged?.call(tabId, false);
      // Fallback không header
      try {
        await c.loadRequest(Uri.parse(target));
      } catch (e2) {
        debugPrint('WebView loadRequest fallback failed: $e2');
      }
    }
  }

  @override
  Widget buildView({
    required String tabId,
    required VoidCallback onCreated,
  }) {
    final controller = _controllers[tabId] ?? _createController(tabId);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _mounted.add(tabId);
      onCreated();
      // Flush URL đang chờ
      final pending = _pendingUrl.remove(tabId);
      if (pending != null && pending.isNotEmpty) {
        await _doLoad(tabId, pending);
      }
    });

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final platformController = controller.platform;
      if (platformController is AndroidWebViewController) {
        return WebViewWidget.fromPlatformCreationParams(
          key: ValueKey('webview_hc_$tabId'),
          params: AndroidWebViewWidgetCreationParams(
            controller: platformController,
            displayWithHybridComposition: true,
          ),
        );
      }
    }

    return WebViewWidget(
      key: ValueKey('webview_$tabId'),
      controller: controller,
    );
  }

  String _normalize(String urlOrQuery) {
    var target = urlOrQuery.trim();
    if (target.isEmpty) return target;
    final looksLikeUrl = target.contains('://') ||
        (target.contains('.') && !target.contains(' '));
    if (!looksLikeUrl) {
      return searchEngineService.searchUrl(target);
    }
    if (!target.contains('://')) {
      target = 'https://$target';
    }
    return target;
  }

  @override
  Future<void> loadUrl(String tabId, String urlOrQuery) async {
    ensureController(tabId);
    final target = _normalize(urlOrQuery);
    if (target.isEmpty) return;

    // Nếu WebView chưa mount → xếp hàng, load khi buildView xong
    if (!_mounted.contains(tabId)) {
      _pendingUrl[tabId] = target;
      onUrlChanged?.call(tabId, target);
      onLoadingChanged?.call(tabId, true);
      return;
    }
    await _doLoad(tabId, target);
  }

  @override
  Future<void> goBack(String tabId) async {
    final c = _controllers[tabId];
    if (c != null && await c.canGoBack()) await c.goBack();
  }

  @override
  Future<void> goForward(String tabId) async {
    final c = _controllers[tabId];
    if (c != null && await c.canGoForward()) await c.goForward();
  }

  @override
  Future<void> reload(String tabId) async {
    await _controllers[tabId]?.reload();
  }

  @override
  Future<void> stopLoading(String tabId) async {
    try {
      await _controllers[tabId]?.runJavaScript('window.stop();');
    } catch (_) {}
  }

  @override
  Future<bool> canGoBack(String tabId) async {
    return await _controllers[tabId]?.canGoBack() ?? false;
  }

  @override
  Future<bool> canGoForward(String tabId) async {
    return await _controllers[tabId]?.canGoForward() ?? false;
  }

  @override
  Future<void> setZoom(String tabId, double factor) async {
    final c = _controllers[tabId];
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
    return await _controllers[tabId]?.currentUrl();
  }

  @override
  Future<String?> getTitle(String tabId) async {
    return await _controllers[tabId]?.getTitle();
  }

  @override
  Future<dynamic> evaluateJavascript(String tabId, String source) async {
    try {
      return await _controllers[tabId]?.runJavaScriptReturningResult(source);
    } catch (_) {
      await _controllers[tabId]?.runJavaScript(source);
      return null;
    }
  }

  @override
  Future<void> clearCookies() async {
    await WebViewCookieManager().clearCookies();
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
      await _controllers[tabId]?.runJavaScript('window.print();');
    } catch (_) {}
  }

  @override
  Future<String?> getUserAgent(String tabId) async {
    try {
      final r = await _controllers[tabId]
          ?.runJavaScriptReturningResult('navigator.userAgent');
      return r?.toString();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> disposeTab(String tabId) async {
    _controllers.remove(tabId);
    _zoomLevels.remove(tabId);
    _pendingUrl.remove(tabId);
    _mounted.remove(tabId);
  }

  @override
  Future<void> dispose() async {
    _controllers.clear();
    _zoomLevels.clear();
    _pendingUrl.clear();
    _mounted.clear();
  }
}
