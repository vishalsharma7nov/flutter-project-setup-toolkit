import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'screens/onboarding_screen.dart';
import 'services/studio_client.dart';
import 'studio_branding.dart';
import 'studio_log.dart';

const _port = String.fromEnvironment('RTK_PORT', defaultValue: '8765');
const _view = String.fromEnvironment('RTK_VIEW', defaultValue: '');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  studioLog('macOS app starting (RTK_PORT=$_port RTK_VIEW=${_view.isEmpty ? '<hub>' : _view})');

  if (Platform.isMacOS) {
    WebViewPlatform.instance = WebKitWebViewPlatform();
    studioLog('WebView: using WebKitWebViewPlatform');
  }

  runApp(ToolkitStudioApp(
    client: StudioClient(_port),
    initialView: _view,
  ));
}

class ToolkitStudioApp extends StatelessWidget {
  const ToolkitStudioApp({
    super.key,
    required this.client,
    required this.initialView,
  });

  final StudioClient client;
  final String initialView;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: studioProductName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: OnboardingScreen(
        client: client,
        initialView: initialView,
      ),
    );
  }
}
