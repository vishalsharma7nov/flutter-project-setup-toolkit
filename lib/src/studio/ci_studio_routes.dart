import 'dart:async';
import 'dart:io';

import '../ci/ci_studio_service.dart';
import '../ci/ci_studio_ui_html.dart';
import '../ci/ci_features.dart';
import '../ci/ci_publish_service.dart';
import '../ci/ci_workflow_spec.dart';
import '../env/env_source.dart';
import 'studio_http.dart';
import 'studio_nav.dart';

class CiStudioRoutes {
  CiStudioRoutes({CiStudioService? service})
      : service = service ?? CiStudioService();

  final CiStudioService service;

  Future<bool> handle(HttpRequest request) async {
    final path = request.uri.path;

    if (request.method == 'GET' && path == '/ci') {
      StudioHttp.respondHtml(
        request.response,
        wrapStudioPage(ciStudioHtml()),
      );
      await request.response.close();
      return true;
    }

    if (request.method == 'GET' && path == '/api/ci/detect') {
      return _handleDetect(request);
    }

    if (request.method == 'POST' && path == '/api/ci/preview') {
      return _handlePreview(request);
    }

    if (request.method == 'POST' && path == '/api/ci/write') {
      return _handleWrite(request);
    }

    if (request.method == 'POST' && path == '/api/ci/test/native') {
      return _handleNativeTest(request);
    }

    if (request.method == 'POST' && path == '/api/ci/test/act') {
      return _handleActTest(request);
    }

    if (request.method == 'GET' && path == '/api/ci/test/status') {
      return _handleTestStatus(request);
    }

    if (request.method == 'POST' && path == '/api/ci/publish') {
      return _handlePublish(request);
    }

    return false;
  }

  Future<bool> _handleDetect(HttpRequest request) async {
    try {
      final projectPath = request.uri.queryParameters['path'];
      if (projectPath == null || projectPath.trim().isEmpty) {
        throw ArgumentError('path is required');
      }
      final data = await service.detect(Directory(projectPath.trim()));
      StudioHttp.respondJson(request.response, 200, data);
    } on Object catch (e) {
      StudioHttp.respondJson(request.response, 400, {'error': '$e'});
    }
    await request.response.close();
    return true;
  }

  Future<bool> _handlePreview(HttpRequest request) async {
    try {
      final payload = await StudioHttp.readJsonBody(request);
      final root = _projectFromPayload(payload);
      final spec = _specFromPayload(payload);
      final data = service.preview(projectRoot: root, spec: spec);
      StudioHttp.respondJson(request.response, 200, data);
    } on Object catch (e) {
      StudioHttp.respondJson(request.response, 400, {'error': '$e'});
    }
    await request.response.close();
    return true;
  }

  Future<bool> _handleWrite(HttpRequest request) async {
    try {
      final payload = await StudioHttp.readJsonBody(request);
      final root = _projectFromPayload(payload);
      final spec = _specFromPayload(payload);
      final data = service.write(projectRoot: root, spec: spec);
      StudioHttp.respondJson(request.response, 200, data);
    } on Object catch (e) {
      StudioHttp.respondJson(request.response, 400, {'error': '$e'});
    }
    await request.response.close();
    return true;
  }

  Future<bool> _handleNativeTest(HttpRequest request) async {
    try {
      if (service.testInProgress) {
        StudioHttp.respondJson(request.response, 409, {
          'error': 'Test already running',
        });
        await request.response.close();
        return true;
      }
      final payload = await StudioHttp.readJsonBody(request);
      final root = _projectFromPayload(payload);
      final spec = _specFromPayload(payload);
      EnvSourceRequest? envOverlay;
      if (payload['env_source'] is Map) {
        envOverlay = EnvSourceRequest.fromJson(
          payload['env_source'] as Map<String, dynamic>,
        );
      }
      unawaited(
        service.runNativeTest(
          projectRoot: root,
          spec: spec,
          envOverlay: envOverlay,
        ),
      );
      StudioHttp.respondJson(request.response, 202, {'status': 'started'});
    } on Object catch (e) {
      StudioHttp.respondJson(request.response, 400, {'error': '$e'});
    }
    await request.response.close();
    return true;
  }

  Future<bool> _handleActTest(HttpRequest request) async {
    if (!ciActStudioEnabled) {
      StudioHttp.respondJson(request.response, 503, {
        'error': 'act testing is not enabled in CI Studio',
      });
      await request.response.close();
      return true;
    }
    try {
      if (service.testInProgress) {
        StudioHttp.respondJson(request.response, 409, {
          'error': 'Test already running',
        });
        await request.response.close();
        return true;
      }
      final payload = await StudioHttp.readJsonBody(request);
      final root = _projectFromPayload(payload);
      final spec = _specFromPayload(payload);
      unawaited(service.runActTest(projectRoot: root, spec: spec));
      StudioHttp.respondJson(request.response, 202, {'status': 'started'});
    } on Object catch (e) {
      StudioHttp.respondJson(request.response, 400, {'error': '$e'});
    }
    await request.response.close();
    return true;
  }

  Future<bool> _handleTestStatus(HttpRequest request) async {
    final offset =
        int.tryParse(request.uri.queryParameters['offset'] ?? '0') ?? 0;
    StudioHttp.respondJson(
      request.response,
      200,
      service.testState.toJson(logOffset: offset),
    );
    await request.response.close();
    return true;
  }

  Future<bool> _handlePublish(HttpRequest request) async {
    try {
      final payload = await StudioHttp.readJsonBody(request);
      final root = _projectFromPayload(payload);
      final spec = _specFromPayload(payload);
      final result = await service.publish(projectRoot: root, spec: spec);
      StudioHttp.respondJson(request.response, 200, result.toJson());
    } on CiPublishBlockedException catch (e) {
      StudioHttp.respondJson(request.response, 403, {'error': e.message});
    } on Object catch (e) {
      StudioHttp.respondJson(request.response, 400, {'error': '$e'});
    }
    await request.response.close();
    return true;
  }

  Directory _projectFromPayload(Map<String, dynamic> payload) {
    final path = payload['path'] as String?;
    if (path == null || path.trim().isEmpty) {
      throw ArgumentError('path is required');
    }
    return Directory(path.trim());
  }

  CiWorkflowSpec _specFromPayload(Map<String, dynamic> payload) {
    final specJson = payload['spec'] as Map<String, dynamic>?;
    if (specJson == null) {
      return CiWorkflowSpec.fromPreset(CiWorkflowPreset.full);
    }
    return CiWorkflowSpec.fromJson(specJson);
  }
}
