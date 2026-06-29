import 'dart:convert';
import 'dart:io';

import '../config.dart';
import 'setup_plan_codec.dart';
import 'setup_studio_models.dart';
import 'setup_studio_service.dart';
import 'setup_studio_ui_html.dart';

class SetupStudioServer {
  SetupStudioServer({
    required this.projectRoot,
    required this.port,
  });

  final Directory? projectRoot;
  final int port;

  final SetupApplyState _applyState = SetupApplyState();
  bool _applyInProgress = false;
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
        ..write(setupStudioHtml());
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

    if (request.method == 'GET' && path == '/api/detect') {
      final projectPath = request.uri.queryParameters['path'];
      if (projectPath == null || projectPath.trim().isEmpty) {
        _respondJson(request.response, 400, {'error': 'Missing path query parameter'});
        await request.response.close();
        return;
      }
      try {
        final root = normalizeProjectDirectory(projectPath);
        _respondJson(request.response, 200, detectSetupProject(root));
      } on Object catch (e) {
        _respondJson(request.response, 400, {'error': '$e'});
      }
      await request.response.close();
      return;
    }

    if (request.method == 'POST' && path == '/api/env-paths') {
      try {
        final body = await _readJsonBody(request);
        final environments = computeEnvPathsFromGui(body);
        _respondJson(request.response, 200, {
          'environments': environments,
          'env_names': environments.keys.toList(),
        });
      } on Object catch (e) {
        _respondJson(request.response, 400, {'error': '$e'});
      }
      await request.response.close();
      return;
    }

    if (request.method == 'POST' && path == '/api/preview') {
      try {
        final body = await _readJsonBody(request);
        final projectPath = body['project'] as String?;
        if (projectPath == null || projectPath.trim().isEmpty) {
          throw ArgumentError('Missing project path');
        }
        final root = normalizeProjectDirectory(projectPath);
        final plan = setupPlanFromGuiMap(root, body);
        _respondJson(request.response, 200, previewSetupPlan(plan));
      } on Object catch (e) {
        _respondJson(request.response, 400, {'error': '$e'});
      }
      await request.response.close();
      return;
    }

    if (request.method == 'GET' && path == '/api/apply/status') {
      final offset = int.tryParse(request.uri.queryParameters['offset'] ?? '0') ?? 0;
      _respondJson(request.response, 200, _applyState.toJson(logOffset: offset));
      await request.response.close();
      return;
    }

    if (request.method == 'POST' && path == '/api/apply') {
      if (_applyInProgress) {
        _respondJson(request.response, 409, {'error': 'Setup is already running'});
        await request.response.close();
        return;
      }

      try {
        final body = await _readJsonBody(request);
        final projectPath = body['project'] as String?;
        if (projectPath == null || projectPath.trim().isEmpty) {
          _respondJson(request.response, 400, {'error': 'Missing project path'});
          await request.response.close();
          return;
        }

        final root = normalizeProjectDirectory(projectPath);
        validateFlutterProject(root);
        final force = body['force'] as bool? ?? false;
        final dryRun = body['dry_run'] as bool? ?? false;

        _applyInProgress = true;
        _respondJson(request.response, 202, {'status': 'started'});
        await request.response.close();

        final service = SetupStudioService(_applyState);
        await service.apply(
          projectRoot: root,
          planPayload: body,
          force: force,
          dryRun: dryRun,
        );
      } on Object catch (e) {
        _applyState
          ..status = SetupApplyStatus.failed
          ..error = '$e'
          ..finishedAt = DateTime.now();
      } finally {
        _applyInProgress = false;
      }
      return;
    }

    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
  }

  Future<Map<String, dynamic>> _readJsonBody(HttpRequest request) async {
    final raw = await utf8.decoder.bind(request).join();
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  void _respondJson(HttpResponse response, int status, Map<String, dynamic> body) {
    response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body));
  }
}
