import 'package:flutter/material.dart';

import 'app.dart';
import 'studio_log.dart';
import 'webview_platform_init_apple.dart';

const _port = String.fromEnvironment('RTK_PORT', defaultValue: '8765');
const _view = String.fromEnvironment('RTK_VIEW', defaultValue: '');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  studioLog(
    'Desktop app starting (RTK_PORT=$_port RTK_VIEW=${_view.isEmpty ? '<hub>' : _view})',
  );

  configureWebViewPlatform();
  studioLog('WebView: using WebKitWebViewPlatform');

  runApp(buildToolkitStudioApp(port: _port, initialView: _view));
}
