import 'dart:io';

import 'package:path/path.dart' as p;

import '../config.dart';
import '../version/version_studio_service.dart';
import '../version/version_studio_ui_html.dart';
import 'studio_http.dart';
import 'studio_nav.dart';
import 'studio_project_state.dart';

class VersionStudioRoutes {
  VersionStudioRoutes({StudioProjectState? projectState})
      : projectState = projectState ?? StudioProjectState();

  final StudioProjectState projectState;

  Future<bool> handle(HttpRequest request) async {
    final path = request.uri.path;

    if (request.method == 'GET' && path == '/version') {
      StudioHttp.respondHtml(
        request.response,
        wrapStudioPage(versionStudioHtml()),
      );
      await request.response.close();
      return true;
    }

    if (request.method == 'GET' && path == '/api/version/environments') {
      final projectPath =
          request.uri.queryParameters['path'] ?? projectState.path;
      if (projectPath == null || projectPath.trim().isEmpty) {
        StudioHttp.respondJson(request.response, 200, {'project_path': null});
        await request.response.close();
        return true;
      }
      try {
        final root = Directory(p.normalize(projectPath.trim()));
        validateFlutterProject(root);
        StudioHttp.respondJson(
          request.response,
          200,
          {
            'project_path': root.path,
            ...versionEnvironmentsForProject(root),
          },
        );
      } on Object catch (e) {
        StudioHttp.respondJson(request.response, 400, {'error': '$e'});
      }
      await request.response.close();
      return true;
    }

    if (request.method == 'POST' && path == '/api/version/preview') {
      try {
        final body = await StudioHttp.readJsonBody(request);
        final projectPath = body['project'] as String?;
        if (projectPath == null) {
          throw ArgumentError('project is required');
        }
        final root = Directory(p.normalize(projectPath.trim()));
        final result = await versionClassifyPreview(
          projectRoot: root,
          commit: body['commit'] as String? ?? 'HEAD',
          envName: body['env'] as String?,
          envFilePath: body['env_file'] as String?,
        );
        StudioHttp.respondJson(request.response, 200, result);
      } on Object catch (e) {
        StudioHttp.respondJson(request.response, 400, {'error': '$e'});
      }
      await request.response.close();
      return true;
    }

    if (request.method == 'POST' && path == '/api/version/apply') {
      try {
        final body = await StudioHttp.readJsonBody(request);
        final projectPath = body['project'] as String?;
        if (projectPath == null) {
          throw ArgumentError('project is required');
        }
        final root = Directory(p.normalize(projectPath.trim()));
        final result = await versionClassifyApply(
          projectRoot: root,
          commit: body['commit'] as String? ?? 'HEAD',
          envName: body['env'] as String?,
          envFilePath: body['env_file'] as String?,
          dryRun: body['dry_run'] as bool? ?? false,
        );
        StudioHttp.respondJson(request.response, 200, result);
      } on Object catch (e) {
        StudioHttp.respondJson(request.response, 400, {'error': '$e'});
      }
      await request.response.close();
      return true;
    }

    return false;
  }
}
