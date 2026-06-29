import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../config.dart';
import 'distribution_build_service.dart';
import 'distribution_models.dart';
import 'distribution_ui_html.dart';

class DistributionServer {
  DistributionServer({
    required this.projectRoot,
    required this.port,
  });

  final Directory? projectRoot;
  final int port;

  final DistributionJobState _jobState = DistributionJobState();
  bool _buildInProgress = false;
  HttpServer? _server;

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    await for (final request in _server!) {
      _handleRequest(request).catchError((Object e) {
        _respondJson(request.response, 500, {'error': '$e'});
      });
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final path = request.uri.path;
    if (request.method == 'GET' && path == '/') {
      request.response
        ..headers.contentType = ContentType.html
        ..write(distributionStudioHtml());
      await request.response.close();
      return;
    }

    if (request.method == 'GET' && path == '/api/bootstrap') {
      _respondJson(request.response, 200, {
        'project_path': projectRoot?.path,
      });
      await request.response.close();
      return;
    }

    if (request.method == 'GET' && path == '/api/project') {
      final projectPath = request.uri.queryParameters['path'];
      if (projectPath == null || projectPath.trim().isEmpty) {
        _respondJson(request.response, 400, {'error': 'Missing path query parameter'});
        await request.response.close();
        return;
      }
      try {
        final root = Directory(p.normalize(projectPath.trim()));
        final info = await loadDistributionProjectInfoAsync(root);
        _respondJson(request.response, 200, {
          'project_path': info.projectPath,
          'environments': info.environments,
          'default_environment': info.defaultEnvironment,
          'flutter_version': info.flutterVersion,
          'is_macos': info.isMacOS,
        });
      } on Object catch (e) {
        _respondJson(request.response, 400, {'error': '$e'});
      }
      await request.response.close();
      return;
    }

    if (request.method == 'GET' && path == '/api/status') {
      final offset = int.tryParse(request.uri.queryParameters['offset'] ?? '0') ?? 0;
      _respondJson(request.response, 200, _jobState.toJson(logOffset: offset));
      await request.response.close();
      return;
    }

    if (request.method == 'POST' && path == '/api/build') {
      if (_buildInProgress) {
        _respondJson(request.response, 409, {'error': 'A build is already running'});
        await request.response.close();
        return;
      }

      final body = await utf8.decoder.bind(request).join();
      final payload = jsonDecode(body) as Map<String, dynamic>;
      final projectPath = payload['project'] as String?;
      final env = payload['env'] as String?;
      final targetName = payload['target'] as String?;

      if (projectPath == null || env == null || targetName == null) {
        _respondJson(request.response, 400, {
          'error': 'Required fields: project, env, target',
        });
        await request.response.close();
        return;
      }

      final target = _parseTarget(targetName);
      if (target == null) {
        _respondJson(request.response, 400, {'error': 'Invalid target: $targetName'});
        await request.response.close();
        return;
      }

      if ((target == DistributionTarget.iosTestFlight ||
              target == DistributionTarget.both) &&
          !Platform.isMacOS) {
        _respondJson(request.response, 400, {
          'error': 'iOS TestFlight builds require macOS with Xcode.',
        });
        await request.response.close();
        return;
      }

      try {
        final root = Directory(p.normalize(projectPath.trim()));
        validateFlutterProject(root);
        _buildInProgress = true;
        _respondJson(request.response, 202, {'status': 'started'});
        await request.response.close();

        final service = DistributionBuildService(_jobState);
        await service.run(projectRoot: root, target: target, envName: env);
      } on Object catch (e) {
        _jobState
          ..status = DistributionJobStatus.failed
          ..error = '$e'
          ..finishedAt = DateTime.now();
      } finally {
        _buildInProgress = false;
      }
      return;
    }

    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
  }

  void _respondJson(HttpResponse response, int status, Map<String, dynamic> body) {
    response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body));
  }
}

DistributionTarget? _parseTarget(String name) {
  for (final target in DistributionTarget.values) {
    if (target.name == name) return target;
  }
  return null;
}
