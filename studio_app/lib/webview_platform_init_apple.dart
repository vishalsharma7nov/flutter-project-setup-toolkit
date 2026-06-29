import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// Registers WebKit for macOS/iOS desktop WebView.
void configureWebViewPlatform() {
  WebViewPlatform.instance = WebKitWebViewPlatform();
}
