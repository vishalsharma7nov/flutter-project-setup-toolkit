import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/studio_client.dart';
import '../studio_branding.dart';
import '../studio_log.dart';

class StudioWebViewScreen extends StatefulWidget {
  const StudioWebViewScreen({
    super.key,
    required this.client,
    required this.projectPath,
    required this.initialView,
    required this.onChangeProject,
  });

  final StudioClient client;
  final String projectPath;
  final String initialView;
  final VoidCallback onChangeProject;

  @override
  State<StudioWebViewScreen> createState() => _StudioWebViewScreenState();
}

class _StudioWebViewScreenState extends State<StudioWebViewScreen> {
  late final WebViewController _controller;
  String _status = 'Loading studio…';
  bool _ready = false;

  String get _viewPath => switch (widget.initialView) {
        'setup' => '/setup',
        'build' => '/build',
        'feature' => '/feature',
        'version' => '/version',
        'quick-test' => '/quick-test',
        _ => '/',
      };

  bool get _skipProjectRegistration => widget.initialView == 'quick-test';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            studioLog('WebView: page finished $url');
            _injectProjectContext();
          },
          onWebResourceError: (error) {
            studioLogError(
              'WebView: resource error ${error.url}',
              error.description,
            );
            if (mounted && !_ready) {
              setState(() {
                _status = 'Loading studio… (${error.description})';
              });
            }
          },
        ),
      );
    unawaited(_openStudio());
  }

  Future<void> _openStudio() async {
    try {
      if (!_skipProjectRegistration) {
        studioLog(
          'WebView: registering project ${widget.projectPath} view=$_viewPath',
        );
        await widget.client.registerProject(widget.projectPath);
      } else {
        studioLog('WebView: opening ${widget.initialView} (no project registration)');
      }
      final url = Uri.parse('http://127.0.0.1:${widget.client.port}$_viewPath');
      studioLog('WebView: loading $url');
      await _controller.loadRequest(url);
    } on Object catch (e, st) {
      studioLogError('WebView: open studio failed', e, st);
      if (mounted) {
        setState(() => _status = '$e');
      }
    }
  }

  Future<void> _injectProjectContext() async {
    if (_skipProjectRegistration) {
      if (mounted) {
        setState(() {
          _ready = true;
          _status = '';
        });
        studioLog('WebView: ready (quick-test, no project context)');
      }
      return;
    }
    studioLog('WebView: injecting project context for ${widget.projectPath}');
    final escapedPath = jsonEncode(widget.projectPath);
    await _controller.runJavaScript('''
      (function () {
        const path = $escapedPath;
        localStorage.setItem("rtk_studio_project_path", path);
        const input = document.getElementById("projectPath");
        if (input) input.value = path;
        if (typeof loadProject === "function") loadProject();
        if (typeof rtkSyncProjectInput === "function") rtkSyncProjectInput();
      })();
    ''');
    if (mounted) {
      setState(() {
        _ready = true;
        _status = '';
      });
      studioLog('WebView: ready');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(studioProductName),
        actions: [
          IconButton(
            tooltip: 'Change project',
            onPressed: widget.onChangeProject,
            icon: const Icon(Icons.folder_open),
          ),
          IconButton(
            tooltip: 'Reload',
            onPressed: () => _controller.reload(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _status.isNotEmpty && !_ready
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_status, textAlign: TextAlign.center),
              ),
            )
          : WebViewWidget(controller: _controller),
    );
  }
}
