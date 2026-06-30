import 'dart:io';

import '../docs/project_docs_service.dart';
import '../docs/project_docs_spec.dart';
import '../docs/project_docs_ui_html.dart';
import 'studio_http.dart';
import 'studio_nav.dart';

class DocsStudioRoutes {
  DocsStudioRoutes({ProjectDocsService? service})
      : service = service ?? ProjectDocsService();

  final ProjectDocsService service;

  Future<bool> handle(HttpRequest request) async {
    final path = request.uri.path;

    if (request.method == 'GET' && path == '/docs') {
      StudioHttp.respondHtml(
        request.response,
        wrapStudioPage(projectDocsStudioHtml()),
      );
      await request.response.close();
      return true;
    }

    if (request.method == 'GET' && path == '/api/docs/detect') {
      return _handleDetect(request);
    }

    if (request.method == 'POST' && path == '/api/docs/preview') {
      return _handlePreview(request);
    }

    if (request.method == 'POST' && path == '/api/docs/write') {
      return _handleWrite(request);
    }

    return false;
  }

  Future<bool> _handleDetect(HttpRequest request) async {
    try {
      final projectPath = request.uri.queryParameters['path'];
      if (projectPath == null || projectPath.trim().isEmpty) {
        throw ArgumentError('path is required');
      }
      final data = service.detect(Directory(projectPath.trim()));
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

  Directory _projectFromPayload(Map<String, dynamic> payload) {
    final path = payload['path'] as String?;
    if (path == null || path.trim().isEmpty) {
      throw ArgumentError('path is required');
    }
    return Directory(path.trim());
  }

  ProjectDocsSpec _specFromPayload(Map<String, dynamic> payload) {
    final specJson = payload['spec'] as Map<String, dynamic>?;
    if (specJson == null) {
      return ProjectDocsSpec.defaults();
    }
    return ProjectDocsSpec.fromJson(specJson);
  }
}
