import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:open_filex/open_filex.dart';

import '../services/apk_install_service.dart';
import '../services/host_prefs.dart';
import '../services/quick_test_client.dart';
import '../services/studio_client.dart';
import '../studio_branding.dart';
import '../studio_log.dart';

class MobileQuickTestApp extends StatelessWidget {
  const MobileQuickTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$studioProductName — Quick Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: const MobileQuickTestScreen(),
    );
  }
}

class MobileQuickTestScreen extends StatefulWidget {
  const MobileQuickTestScreen({super.key});

  @override
  State<MobileQuickTestScreen> createState() => _MobileQuickTestScreenState();
}

class _MobileQuickTestScreenState extends State<MobileQuickTestScreen> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '8765');
  final _gitUrlController = TextEditingController();
  final _gitRefController = TextEditingController(text: 'main');
  final _gitTokenController = TextEditingController();

  HostPrefs? _prefs;
  StudioClient? _client;
  QuickTestClient? _quickTest;
  StudioEnvironment? _environment;

  bool _loadingPrefs = true;
  bool _connecting = false;
  bool _checkingRepo = false;
  bool _running = false;
  String? _error;
  String? _iosGuidance;
  Map<String, dynamic>? _preflight;
  String _status = 'idle';
  final _logLines = <String>[];
  int _logOffset = 0;
  Timer? _pollTimer;
  List<String> _artifactUrls = const [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _hostController.dispose();
    _portController.dispose();
    _gitUrlController.dispose();
    _gitRefController.dispose();
    _gitTokenController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final prefs = await HostPrefs.load();
    final savedHost = prefs.host;
    if (savedHost != null && savedHost.isNotEmpty) {
      _hostController.text = savedHost;
      _portController.text = prefs.port;
    }
    setState(() {
      _prefs = prefs;
      _loadingPrefs = false;
    });
    if (savedHost != null && savedHost.isNotEmpty) {
      await _connect(save: false);
    }
  }

  Future<void> _connect({required bool save}) async {
    final host = _hostController.text.trim();
    final port = _portController.text.trim().isEmpty ? '8765' : _portController.text.trim();
    if (host.isEmpty) {
      setState(() => _error = 'Enter your Mac IP address.');
      return;
    }

    setState(() {
      _connecting = true;
      _error = null;
      _environment = null;
    });

    try {
      final client = StudioClient(port, host: host);
      await client.waitForServer(timeout: const Duration(seconds: 15));
      final env = await client.fetchEnvironment();
      if (save) {
        await _prefs?.save(host: host, port: port);
      }
      setState(() {
        _client = client;
        _quickTest = QuickTestClient(client);
        _environment = env;
      });
    } on Object catch (e, st) {
      studioLogError('Mobile: connect failed', e, st);
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _checkRepo() async {
    final quickTest = _quickTest;
    if (quickTest == null) {
      setState(() => _error = 'Connect to your Mac build host first.');
      return;
    }
    final url = _gitUrlController.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Paste a Git repository URL.');
      return;
    }

    setState(() {
      _checkingRepo = true;
      _error = null;
      _preflight = null;
      _iosGuidance = null;
    });

    try {
      final auth = _gitTokenController.text.trim().isEmpty ? 'none' : 'https_token';
      final result = await quickTest.preflight(
        source: gitSourcePayload(
          url: url,
          ref: _gitRefController.text,
          auth: auth,
          token: _gitTokenController.text.trim().isEmpty
              ? null
              : _gitTokenController.text.trim(),
        ),
      );
      setState(() => _preflight = result);
    } on Object catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _checkingRepo = false);
    }
  }

  Future<void> _runQuickTest() async {
    final quickTest = _quickTest;
    if (quickTest == null || _preflight == null) {
      setState(() => _error = 'Check repo before running a build.');
      return;
    }

    final platform = quickTestPlatformForDevice();
    if (platform == 'ios' && (_environment?.canBuildIos != true)) {
      setState(() {
        _error = 'Mac build host cannot build iOS (Xcode required).';
      });
      return;
    }
    if (platform == 'android' && (_environment?.canBuildAndroid != true)) {
      setState(() {
        _error = 'Mac build host cannot build Android (Flutter/Android SDK required).';
      });
      return;
    }

    setState(() {
      _running = true;
      _error = null;
      _iosGuidance = null;
      _status = 'running';
      _logLines.clear();
      _logOffset = 0;
      _artifactUrls = const [];
    });

    try {
      final auth = _gitTokenController.text.trim().isEmpty ? 'none' : 'https_token';
      await quickTest.run(
        source: gitSourcePayload(
          url: _gitUrlController.text.trim(),
          ref: _gitRefController.text,
          auth: auth,
          token: _gitTokenController.text.trim().isEmpty
              ? null
              : _gitTokenController.text.trim(),
        ),
        platform: platform,
        includeTestflightIpa: Platform.isIOS,
      );
      _startPolling();
    } on Object catch (e) {
      setState(() {
        _running = false;
        _status = 'failed';
        _error = '$e';
      });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      unawaited(_pollStatus());
    });
    unawaited(_pollStatus());
  }

  Future<void> _pollStatus() async {
    final quickTest = _quickTest;
    if (quickTest == null) return;

    try {
      final data = await quickTest.pollStatus(offset: _logOffset);
      final logs = data['logs'];
      if (logs is List && logs.isNotEmpty) {
        setState(() {
          _logLines.addAll(logs.map((e) => e.toString()));
          _logOffset = data['log_total'] as int? ?? _logOffset + logs.length;
        });
      }

      final status = data['status'] as String? ?? 'idle';
      if (status == 'running') return;

      _pollTimer?.cancel();
      _pollTimer = null;

      final artifactUrls = (data['artifact_urls'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();

      setState(() {
        _running = false;
        _status = status;
        _artifactUrls = artifactUrls;
      });

      if (status == 'succeeded') {
        await _handleSuccess(artifactUrls, data);
      } else if (data['error'] != null) {
        setState(() => _error = data['error'].toString());
      }
    } on Object catch (e) {
      _pollTimer?.cancel();
      _pollTimer = null;
      if (mounted) {
        setState(() {
          _running = false;
          _status = 'failed';
          _error = '$e';
        });
      }
    }
  }

  Future<void> _handleSuccess(
    List<String> artifactUrls,
    Map<String, dynamic> data,
  ) async {
    if (Platform.isAndroid) {
      final paths = (data['artifact_paths'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList();
      String? apkUrl;
      for (var i = 0; i < paths.length; i++) {
        if (paths[i].toLowerCase().endsWith('.apk')) {
          apkUrl = i < artifactUrls.length
              ? artifactUrls[i]
              : '/api/quick-test/artifacts/download?path=${Uri.encodeComponent(paths[i])}';
          break;
        }
      }
      apkUrl ??= artifactUrls.isNotEmpty ? artifactUrls.first : null;
      if (apkUrl == null) {
        setState(() => _error = 'Build succeeded but no APK artifact was found.');
        return;
      }
      try {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/quick-test.apk');
        await _quickTest!.downloadArtifact(
          relativeUrl: apkUrl,
          destination: file,
        );
        final result = await ApkInstallService().installApk(file);
        if (result.type != ResultType.done) {
          setState(() {
            _error =
                'APK ready. If install did not start, enable Install unknown apps '
                'for this app in Settings. (${result.message})';
          });
        }
      } on Object catch (e) {
        setState(() => _error = 'Download/install failed: $e');
      }
      return;
    }

    if (Platform.isIOS) {
      setState(() {
        _iosGuidance =
            'Build finished on your Mac. WiFi-only iPhones cannot sideload directly.\n\n'
            '• USB to Mac: run Quick Test from Mac Studio with the iPhone connected.\n'
            '• TestFlight: upload the IPA from your Mac (Xcode Organizer / Transporter).\n'
            '${artifactUrls.isNotEmpty ? '\nArtifact: ${artifactUrls.join(', ')}' : ''}';
      });
    }
  }

  Future<void> _cancelRun() async {
    await _quickTest?.cancel();
    _pollTimer?.cancel();
    _pollTimer = null;
    setState(() {
      _running = false;
      _status = 'cancelled';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingPrefs) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final platformLabel = Platform.isAndroid
        ? 'Android'
        : Platform.isIOS
            ? 'iOS'
            : 'device';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Test'),
        actions: [
          if (_client != null)
            IconButton(
              tooltip: 'Disconnect',
              onPressed: () async {
                await _prefs?.clear();
                setState(() {
                  _client = null;
                  _quickTest = null;
                  _environment = null;
                  _preflight = null;
                });
              },
              icon: const Icon(Icons.link_off),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Paste a Git repo — your Mac builds for this $platformLabel device.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _sectionTitle(context, 'Mac build host'),
          TextField(
            controller: _hostController,
            enabled: !_connecting && !_running,
            decoration: const InputDecoration(
              labelText: 'Mac IP address',
              hintText: '192.168.1.42',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _portController,
            enabled: !_connecting && !_running,
            decoration: const InputDecoration(
              labelText: 'Port',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _connecting || _running ? null : () => _connect(save: true),
            icon: _connecting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.link),
            label: Text(_connecting ? 'Connecting…' : 'Connect to Mac'),
          ),
          if (_environment != null) ...[
            const SizedBox(height: 8),
            Text(
              'Mac: Flutter ${_environment!.flutterInstalled ? (_environment!.flutterVersion ?? 'ok') : 'missing'}'
              '${_environment!.canBuildIos ? ' · iOS builds ok' : ''}'
              '${_environment!.canBuildAndroid ? ' · Android builds ok' : ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 20),
          _sectionTitle(context, 'Git repository'),
          TextField(
            controller: _gitUrlController,
            enabled: !_running,
            decoration: const InputDecoration(
              labelText: 'Repository URL',
              hintText: 'https://github.com/org/app.git',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _gitRefController,
            enabled: !_running,
            decoration: const InputDecoration(
              labelText: 'Branch / tag',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _gitTokenController,
            enabled: !_running,
            decoration: const InputDecoration(
              labelText: 'HTTPS token (private repos, optional)',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _checkingRepo || _running || _client == null ? null : _checkRepo,
            icon: _checkingRepo
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
            label: Text(_checkingRepo ? 'Checking…' : 'Check repo'),
          ),
          if (_preflight != null) ...[
            const SizedBox(height: 8),
            Text(
              _preflight!['structure_complete'] == true
                  ? 'Flutter project looks good.'
                  : 'Structure warnings — build may still proceed.',
              style: TextStyle(
                color: _preflight!['structure_complete'] == true
                    ? Colors.green
                    : Theme.of(context).colorScheme.tertiary,
              ),
            ),
          ],
          const SizedBox(height: 20),
          _sectionTitle(context, 'Build & install'),
          FilledButton.icon(
            onPressed: _running || _preflight == null || _client == null
                ? null
                : _runQuickTest,
            icon: _running
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Platform.isAndroid ? Icons.android : Icons.phone_iphone),
            label: Text(
              _running
                  ? 'Building…'
                  : 'Build & install on this $platformLabel',
            ),
          ),
          if (_running)
            TextButton(onPressed: _cancelRun, child: const Text('Cancel')),
          if (_status != 'idle')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Status: $_status'),
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Material(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!),
              ),
            ),
          ],
          if (_iosGuidance != null) ...[
            const SizedBox(height: 12),
            Material(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_iosGuidance!),
              ),
            ),
          ],
          if (_artifactUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Artifacts', style: Theme.of(context).textTheme.titleSmall),
            ..._artifactUrls.map((url) => Text(url, style: Theme.of(context).textTheme.bodySmall)),
          ],
          const SizedBox(height: 20),
          _sectionTitle(context, 'Log'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Text(
              _logLines.isEmpty ? 'Waiting…' : _logLines.join('\n'),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'On Mac run: ./scripts/toolkit-studio.sh --host lan',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
