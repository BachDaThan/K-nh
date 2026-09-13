import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_geckoview/webview_flutter_geckoview.dart';

/// Gắn GeckoView làm implementation của webview_flutter (Android).
Future<void> registerGeckoWebViewPlatform() async {
  WebViewPlatform.instance = GeckoWebViewPlatform();
}
