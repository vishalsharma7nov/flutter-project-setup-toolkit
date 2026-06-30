import 'dart:async';
import 'dart:convert';

import 'package:file_selector/file_selector.dart';
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
        'ci' => '/ci',
        'qa' => '/qa',
        'docs' => '/docs',
        'packages' => '/packages',
        'doctor' => '/doctor',
        _ => '/',
      };

  bool get _skipProjectRegistration =>
      (widget.initialView == 'quick-test' && widget.projectPath.isEmpty) ||
      (widget.initialView == 'doctor' && widget.projectPath.isEmpty);

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'RtkFolderPicker',
        onMessageReceived: (message) {
          unawaited(_handleFolderPickRequest(message.message));
        },
      )
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

  Future<void> _handleFolderPickRequest(String raw) async {
    String requestId = '';
    try {
      final payload = jsonDecode(raw) as Map<String, dynamic>;
      requestId = payload['id'] as String? ?? '';
      final path = await getDirectoryPath(
        confirmButtonText: 'Select project folder',
        initialDirectory: payload['initial'] as String?,
      );
      final escapedId = jsonEncode(requestId);
      final escapedPath = jsonEncode(path);
      await _controller.runJavaScript(
        'window.rtkOnFolderPicked($escapedId, $escapedPath);',
      );
    } on Object catch (e, st) {
      studioLogError('WebView: folder pick failed', e, st);
      if (requestId.isNotEmpty) {
        final escapedId = jsonEncode(requestId);
        await _controller.runJavaScript(
          'window.rtkOnFolderPicked($escapedId, null);',
        );
      }
    }
  }

  Future<void> _injectFolderPickerBridge() async {
    await _controller.runJavaScript(r'''
      (function () {
        if (window.rtkNativePickFolder) return;
        window.rtkFolderPickResolvers = window.rtkFolderPickResolvers || {};
        window.rtkNativePickFolder = function (initial) {
          return new Promise(function (resolve) {
            const id = "pick_" + Date.now() + "_" + Math.random().toString(16).slice(2);
            window.rtkFolderPickResolvers[id] = resolve;
            RtkFolderPicker.postMessage(JSON.stringify({ id: id, initial: initial || "" }));
          });
        };
        window.rtkOnFolderPicked = function (id, path) {
          const resolve = window.rtkFolderPickResolvers[id];
          if (resolve) resolve(path || null);
          delete window.rtkFolderPickResolvers[id];
        };
      })();
    ''');
  }

  Future<void> _injectProjectContext() async {
    await _injectFolderPickerBridge();
    if (_skipProjectRegistration) {
      if (mounted) {
        setState(() {
          _ready = true;
          _status = '';
        });
        studioLog('WebView: ready (${widget.initialView}, no project context)');
      }
      return;
    }
    studioLog('WebView: injecting project context for ${widget.projectPath}');
    final escapedPath = jsonEncode(widget.projectPath);
    final quickTestLocal = widget.initialView == 'quick-test';
    await _controller.runJavaScript('''
      (function () {
        const path = $escapedPath;
        localStorage.setItem("rtk_studio_project_path", path);
        const input = document.getElementById("projectPath");
        if (input) input.value = path;
        ${quickTestLocal ? '''
        const localMode = document.querySelector('input[name="sourceMode"][value="local"]');
        if (localMode) localMode.checked = true;
        if (typeof syncSourcePanels === "function") syncSourcePanels();
        ''' : '''
        if (typeof loadProject === "function") loadProject();
        '''}
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
