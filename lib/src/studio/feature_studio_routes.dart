import 'dart:io';

import 'package:path/path.dart' as p;

import '../config.dart';
import '../feature/feature_studio_service.dart';
import '../feature/feature_studio_models.dart';
import '../feature/feature_studio_ui_html.dart';
import '../feature_scaffold.dart';
import '../models.dart';
import '../setup/setup_arch_api_codec.dart';
import 'studio_http.dart';
import 'studio_nav.dart';
import 'studio_project_state.dart';

class FeatureStudioRoutes {
  FeatureStudioRoutes({StudioProjectState? projectState})
      : projectState = projectState ?? StudioProjectState();

  final StudioProjectState projectState;
  final FeatureApplyState applyState = FeatureApplyState();
  bool applyInProgress = false;

  Future<bool> handle(HttpRequest request) async {
    final path = request.uri.path;

    if (request.method == 'GET' && path == '/feature') {
      StudioHttp.respondHtml(
        request.response,
        wrapStudioPage(featureStudioHtml()),
      );
      await request.response.close();
      return true;
    }

    if (request.method == 'GET' &&
        (path == '/api/feature/detect' || path == '/api/feature/bootstrap')) {
      final projectPath =
          request.uri.queryParameters['path'] ?? projectState.path;
      if (projectPath == null || projectPath.trim().isEmpty) {
        StudioHttp.respondJson(request.response, 200, {
          'project_path': null,
        });
        await request.response.close();
        return true;
      }
      try {
        final root = Directory(p.normalize(projectPath.trim()));
        StudioHttp.respondJson(
          request.response,
          200,
          detectFeatureProject(root),
        );
      } on Object catch (e) {
        StudioHttp.respondJson(request.response, 400, {'error': '$e'});
      }
      await request.response.close();
      return true;
    }

    if (request.method == 'POST' && path == '/api/feature/preview') {
      try {
        final body = await StudioHttp.readJsonBody(request);
        final projectPath = body['project'] as String?;
        final feature = body['feature'] as String?;
        if (projectPath == null || feature == null) {
          throw ArgumentError('project and feature are required');
        }
        final root = Directory(p.normalize(projectPath.trim()));
        final sm = StateManagement.parse(body['state_management'] as String?) ??
            StateManagement.none;
        final overrides = FeatureScaffoldOverrides.fromBody(body);
        StudioHttp.respondJson(
          request.response,
          200,
          previewFeatureScaffold(
            projectRoot: root,
            featureName: feature,
            basePath: body['base_path'] as String? ?? 'lib/features',
            stateManagement: sm,
            architecture: overrides.architecture,
            api: overrides.api,
          ),
        );
      } on Object catch (e) {
        StudioHttp.respondJson(request.response, 400, {'error': '$e'});
      }
      await request.response.close();
      return true;
    }

    if (request.method == 'GET' && path == '/api/feature/status') {
      final offset =
          int.tryParse(request.uri.queryParameters['offset'] ?? '0') ?? 0;
      StudioHttp.respondJson(
        request.response,
        200,
        applyState.toJson(logOffset: offset),
      );
      await request.response.close();
      return true;
    }

    if (request.method == 'POST' && path == '/api/feature/apply') {
      if (applyInProgress) {
        StudioHttp.respondJson(
          request.response,
          409,
          {'error': 'Feature scaffold is already running'},
        );
        await request.response.close();
        return true;
      }

      try {
        final body = await StudioHttp.readJsonBody(request);
        final projectPath = body['project'] as String?;
        final feature = body['feature'] as String?;
        if (projectPath == null || feature == null) {
          StudioHttp.respondJson(request.response, 400, {
            'error': 'project and feature are required',
          });
          await request.response.close();
          return true;
        }

        final root = Directory(p.normalize(projectPath.trim()));
        validateFlutterProject(root);
        final sm = StateManagement.parse(body['state_management'] as String?) ??
            StateManagement.none;
        final dryRun = body['dry_run'] as bool? ?? false;
        final overrides = FeatureScaffoldOverrides.fromBody(body);

        applyInProgress = true;
        StudioHttp.respondJson(request.response, 202, {'status': 'started'});
        await request.response.close();

        final service = FeatureStudioService(applyState);
        await service.apply(
          projectRoot: root,
          featureName: feature,
          basePath: body['base_path'] as String? ?? 'lib/features',
          stateManagement: sm,
          dryRun: dryRun,
          architecture: overrides.architecture,
          api: overrides.api,
        );
      } on Object catch (e) {
        applyState
          ..status = FeatureApplyStatus.failed
          ..error = '$e'
          ..finishedAt = DateTime.now();
      } finally {
        applyInProgress = false;
      }
      return true;
    }

    if (request.method == 'POST' && path == '/api/feature/save-config') {
      try {
        final body = await StudioHttp.readJsonBody(request);
        final projectPath = body['project'] as String?;
        if (projectPath == null) {
          throw ArgumentError('project is required');
        }
        final root = Directory(p.normalize(projectPath.trim()));
        validateFlutterProject(root);
        final result = saveArchitectureApiDefaults(
          projectRoot: root,
          body: body,
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
