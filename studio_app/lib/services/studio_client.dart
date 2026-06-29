import 'dart:convert';
import 'dart:io';

import '../studio_branding.dart';
import '../studio_log.dart';

class StudioEnvironment {
  StudioEnvironment({
    required this.dartInstalled,
    required this.dartVersion,
    required this.flutterInstalled,
    required this.flutterVersion,
    required this.flutterHint,
    required this.xcodeInstalled,
    required this.macos,
    required this.capabilities,
  });

  factory StudioEnvironment.fromJson(Map<String, dynamic> json) {
    final dart = json['dart'] as Map<String, dynamic>? ?? {};
    final flutter = json['flutter'] as Map<String, dynamic>? ?? {};
    final xcode = json['xcode'] as Map<String, dynamic>? ?? {};
    return StudioEnvironment(
      dartInstalled: dart['installed'] as bool? ?? false,
      dartVersion: dart['version'] as String?,
      flutterInstalled: flutter['installed'] as bool? ?? false,
      flutterVersion: flutter['version'] as String?,
      flutterHint: flutter['hint'] as String?,
      xcodeInstalled: xcode['installed'] as bool? ?? false,
      macos: json['macos'] as bool? ?? Platform.isMacOS,
      capabilities: Map<String, dynamic>.from(
        json['capabilities'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  final bool dartInstalled;
  final String? dartVersion;
  final bool flutterInstalled;
  final String? flutterVersion;
  final String? flutterHint;
  final bool xcodeInstalled;
  final bool macos;
  final Map<String, dynamic> capabilities;

  bool get canUseStudio => dartInstalled;

  bool get canBuildAndroid => capabilities['build_android'] as bool? ?? false;

  bool get canBuildIos => capabilities['build_ios'] as bool? ?? false;
}

class ProjectAnalysis {
  ProjectAnalysis({
    required this.projectPath,
    required this.compatible,
    required this.canRepair,
    required this.issues,
    required this.flutterInstalled,
  });

  factory ProjectAnalysis.fromJson(Map<String, dynamic> json) {
    return ProjectAnalysis(
      projectPath: json['project_path'] as String? ?? '',
      compatible: json['compatible'] as bool? ?? false,
      canRepair: json['can_repair'] as bool? ?? false,
      issues: List<String>.from(json['issues'] as List<dynamic>? ?? []),
      flutterInstalled: json['flutter_installed'] as bool? ?? false,
    );
  }

  final String projectPath;
  final bool compatible;
  final bool canRepair;
  final List<String> issues;
  final bool flutterInstalled;

  @override
  String toString() =>
      'ProjectAnalysis(compatible=$compatible, canRepair=$canRepair, issues=$issues)';
}

class StudioClient {
  StudioClient(String preferredPort)
      : _preferredPort = preferredPort,
        _activePort = preferredPort {
    studioLog('StudioClient created (preferred port $_preferredPort)');
  }

  final String _preferredPort;
  String _activePort;

  String get port => _activePort;
  Uri _baseFor(String port) => Uri.parse('http://127.0.0.1:$port');

  Uri _urlFor(
    String path, {
    String? port,
    Map<String, String>? queryParameters,
  }) {
    return _baseFor(port ?? _activePort).replace(
      path: path,
      queryParameters: queryParameters ?? const {},
    );
  }

  Future<void> waitForServer({Duration timeout = const Duration(seconds: 45)}) async {
    studioLog('Waiting for studio server (timeout ${timeout.inSeconds}s)…');
    final deadline = DateTime.now().add(timeout);
    final preferred = int.tryParse(_preferredPort) ?? 8765;
    final ports = <int>{
      preferred,
      for (var p = 8765; p <= 8785; p++) p,
    };

    while (DateTime.now().isBefore(deadline)) {
      for (final port in ports) {
        if (await _pingPort(port)) {
          if (_activePort != '$port') {
            studioLog(
              'Studio server found on port $port'
              '${port != preferred ? ' (preferred was $preferred)' : ''}',
            );
          }
          _activePort = '$port';
          return;
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
    studioLogError(
      'Studio server not reachable on ports 8765–8785',
      StateError('timeout'),
    );
    throw StateError(
      'Could not reach $studioProductName (tried ports 8765–8785). '
      'Start with: ./scripts/toolkit-studio.sh',
    );
  }

  Future<bool> _pingPort(int port) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(
        _urlFor('/api/environment', port: '$port'),
      );
      final response = await request.close();
      await response.drain<void>();
      return response.statusCode == 200;
    } catch (e) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  Future<StudioEnvironment> fetchEnvironment() async {
    studioLog('GET /api/environment');
    final env = await _getJson('/api/environment', StudioEnvironment.fromJson);
    studioLog(
      'Environment: dart=${env.dartInstalled} flutter=${env.flutterInstalled} '
      'xcode=${env.xcodeInstalled}',
    );
    return env;
  }

  Future<ProjectAnalysis> analyzeProject(String projectPath) async {
    studioLog('Analyzing project: $projectPath');
    final analysis = await _getJson(
      '/api/project/analyze',
      ProjectAnalysis.fromJson,
      queryParameters: {'path': projectPath},
    );
    studioLog('Analyze result: $analysis');
    return analysis;
  }

  Future<String> registerProject(
    String projectPath, {
    bool repair = false,
  }) async {
    studioLog('POST /api/project path=$projectPath repair=$repair');
    final data = await _postJson('/api/project', {
      'project': projectPath,
      'repair': repair,
    });
    if (data.containsKey('error')) {
      throw StateError(data['error'] as String? ?? 'Invalid Flutter project');
    }
    final registered = data['project_path'] as String? ?? projectPath;
    studioLog('Project registered: $registered');
    return registered;
  }

  Future<String> createProject({
    required String parentPath,
    required String projectName,
  }) async {
    studioLog('POST /api/project/create parent=$parentPath name=$projectName');
    final data = await _postJson('/api/project/create', {
      'parent_path': parentPath,
      'project_name': projectName,
    });
    if (data.containsKey('error')) {
      throw StateError(data['error'] as String? ?? 'Could not create project');
    }
    final created = data['project_path'] as String? ?? '';
    studioLog('Project created: $created');
    return created;
  }

  Future<T> _getJson<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, String>? queryParameters,
  }) async {
    final client = HttpClient();
    final url = _urlFor(path, queryParameters: queryParameters);
    try {
      studioLog('HTTP GET $url');
      final request = await client.getUrl(url);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      studioLog(
        'HTTP GET ${response.statusCode} $path body=${studioLogPreview(body)}',
      );
      final data = _decodeJsonMap(body, path: path, statusCode: response.statusCode);
      if (response.statusCode != 200) {
        throw StateError(data['error'] as String? ?? 'Request failed ($path)');
      }
      return fromJson(data);
    } on Object catch (e, st) {
      studioLogError('HTTP GET failed $path', e, st);
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final client = HttpClient();
    final url = _urlFor(path);
    try {
      studioLog('HTTP POST $url payload=${studioLogPreview(jsonEncode(payload))}');
      final request = await client.postUrl(url);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(payload));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      studioLog(
        'HTTP POST ${response.statusCode} $path body=${studioLogPreview(body)}',
      );
      final data = _decodeJsonMap(body, path: path, statusCode: response.statusCode);
      if (response.statusCode != 200) {
        final analysis = data['analysis'];
        final extra = analysis is Map ? '\n${analysis['issues']}' : '';
        throw StateError(
          (data['error'] as String? ?? 'Request failed ($path)') + extra,
        );
      }
      return data;
    } on Object catch (e, st) {
      studioLogError('HTTP POST failed $path', e, st);
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  Map<String, dynamic> _decodeJsonMap(
    String body, {
    required String path,
    required int statusCode,
  }) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      studioLogError(
        'Empty response body for $path (HTTP $statusCode)',
        const FormatException('empty body'),
      );
      throw StateError(
        'Empty response from studio server ($path, HTTP $statusCode). '
        'Restart ./scripts/toolkit-studio.sh — the server port may have changed.',
      );
    }
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is! Map<String, dynamic>) {
        studioLog('Non-object JSON from $path: ${decoded.runtimeType}');
        throw StateError('Unexpected response from $path (not a JSON object).');
      }
      return decoded;
    } on FormatException catch (e) {
      studioLogError(
        'JSON parse failed for $path (HTTP $statusCode) body=${studioLogPreview(trimmed)}',
        e,
      );
      throw StateError(
        'Invalid JSON from studio server ($path): $e. '
        'Restart ./scripts/toolkit-studio.sh.',
      );
    }
  }
}
