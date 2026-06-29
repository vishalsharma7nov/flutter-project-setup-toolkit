import 'dart:io';

import '../architecture/architecture_audit.dart';
import '../architecture/architecture_detect.dart';
import '../architecture/architecture_migrate.dart';
import '../config.dart';
import '../setup/setup_plan_codec.dart';
import '../setup/setup_studio_models.dart';
import '../setup/setup_studio_service.dart';
import '../setup/setup_studio_ui_html.dart';
import 'studio_http.dart';
import 'studio_nav.dart';
import 'studio_project_state.dart';

class SetupStudioRoutes {
  SetupStudioRoutes({StudioProjectState? projectState})
      : projectState = projectState ?? StudioProjectState();

  final StudioProjectState projectState;
  final SetupApplyState applyState = SetupApplyState();
  bool applyInProgress = false;

  Future<bool> handle(HttpRequest request) async {
    final path = request.uri.path;

    if (request.method == 'GET' && (path == '/setup' || path == '/')) {
      if (path == '/setup') {
        StudioHttp.respondHtml(request.response, wrapStudioPage(setupStudioHtml()));
        await request.response.close();
        return true;
      }
      return false;
    }

    if (request.method == 'GET' &&
        (path == '/api/bootstrap' || path == '/api/setup/bootstrap')) {
      StudioHttp.respondJson(request.response, 200, {
        'project_path': projectState.path,
        'project_required': true,
      });
      await request.response.close();
      return true;
    }

    if (request.method == 'GET' &&
        (path == '/api/detect' || path == '/api/setup/detect')) {
      return _handleDetect(request);
    }

    if (request.method == 'GET' &&
        (path == '/api/setup/architecture/detect' ||
            path == '/api/architecture/detect')) {
      return _handleArchitectureDetect(request);
    }

    if (request.method == 'GET' &&
        (path == '/api/setup/architecture/audit' ||
            path == '/api/architecture/audit')) {
      return _handleArchitectureAudit(request);
    }

    if (request.method == 'POST' &&
        (path == '/api/setup/architecture/migrate' ||
            path == '/api/architecture/migrate')) {
      return _handleArchitectureMigrate(request);
    }

    if (request.method == 'POST' &&
        (path == '/api/env-paths' || path == '/api/setup/env-paths')) {
      return _handleEnvPaths(request);
    }

    if (request.method == 'POST' &&
        (path == '/api/preview' || path == '/api/setup/preview')) {
      return _handlePreview(request);
    }

    if (request.method == 'GET' &&
        (path == '/api/apply/status' || path == '/api/setup/apply/status')) {
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

    if (request.method == 'POST' &&
        (path == '/api/apply' || path == '/api/setup/apply')) {
      return _handleApply(request);
    }

    return false;
  }

  Future<bool> _handleDetect(HttpRequest request) async {
    final projectPath = request.uri.queryParameters['path'];
    if (projectPath == null || projectPath.trim().isEmpty) {
      StudioHttp.respondJson(
        request.response,
        400,
        {'error': 'Missing path query parameter'},
      );
      await request.response.close();
      return true;
    }
    try {
      final root = normalizeProjectDirectory(projectPath);
      StudioHttp.respondJson(
        request.response,
        200,
        detectSetupProject(root),
      );
    } on Object catch (e) {
      StudioHttp.respondJson(request.response, 400, {'error': '$e'});
    }
    await request.response.close();
    return true;
  }

  Future<bool> _handleArchitectureDetect(HttpRequest request) async {
    final projectPath = request.uri.queryParameters['path'];
    if (projectPath == null || projectPath.trim().isEmpty) {
      StudioHttp.respondJson(
        request.response,
        400,
        {'error': 'Missing path query parameter'},
      );
      await request.response.close();
      return true;
    }
    try {
      final root = normalizeProjectDirectory(projectPath);
      validateFlutterProject(root);
      final result = detectArchitectureLayout(root);
      StudioHttp.respondJson(request.response, 200, result.toJson());
    } on Object catch (e) {
      StudioHttp.respondJson(request.response, 400, {'error': '$e'});
    }
    await request.response.close();
    return true;
  }

  Future<bool> _handleArchitectureAudit(HttpRequest request) async {
    final projectPath = request.uri.queryParameters['path'];
    if (projectPath == null || projectPath.trim().isEmpty) {
      StudioHttp.respondJson(
        request.response,
        400,
        {'error': 'Missing path query parameter'},
      );
      await request.response.close();
      return true;
    }
    try {
      final root = normalizeProjectDirectory(projectPath);
      validateFlutterProject(root);
      final report = runArchitectureAudit(root);
      StudioHttp.respondJson(request.response, 200, report.toJson());
    } on Object catch (e) {
      StudioHttp.respondJson(request.response, 400, {'error': '$e'});
    }
    await request.response.close();
    return true;
  }

  Future<bool> _handleArchitectureMigrate(HttpRequest request) async {
    try {
      final body = await StudioHttp.readJsonBody(request);
      final projectPath = body['project'] as String? ?? body['path'] as String?;
      if (projectPath == null || projectPath.trim().isEmpty) {
        throw ArgumentError('Missing project path');
      }
      final dryRun = body['dry_run'] as bool? ?? true;
      final root = normalizeProjectDirectory(projectPath);
      validateFlutterProject(root);
      final plan = dryRun
          ? planArchitectureMigration(root)
          : await applyArchitectureMigration(root, dryRun: false);
      StudioHttp.respondJson(request.response, 200, plan.toJson());
    } on Object catch (e) {
      StudioHttp.respondJson(request.response, 400, {'error': '$e'});
    }
    await request.response.close();
    return true;
  }

  Future<bool> _handleEnvPaths(HttpRequest request) async {
    try {
      final body = await StudioHttp.readJsonBody(request);
      final environments = computeEnvPathsFromGui(body);
      StudioHttp.respondJson(request.response, 200, {
        'environments': environments,
        'env_names': environments.keys.toList(),
      });
    } on Object catch (e) {
      StudioHttp.respondJson(request.response, 400, {'error': '$e'});
    }
    await request.response.close();
    return true;
  }

  Future<bool> _handlePreview(HttpRequest request) async {
    try {
      final body = await StudioHttp.readJsonBody(request);
      final projectPath = body['project'] as String?;
      if (projectPath == null || projectPath.trim().isEmpty) {
        throw ArgumentError('Missing project path');
      }
      final root = normalizeProjectDirectory(projectPath);
      final plan = setupPlanFromGuiMap(root, body);
      StudioHttp.respondJson(request.response, 200, previewSetupPlan(plan));
    } on Object catch (e) {
      StudioHttp.respondJson(request.response, 400, {'error': '$e'});
    }
    await request.response.close();
    return true;
  }

  Future<bool> _handleApply(HttpRequest request) async {
    if (applyInProgress) {
      StudioHttp.respondJson(
        request.response,
        409,
        {'error': 'Setup is already running'},
      );
      await request.response.close();
      return true;
    }

    try {
      final body = await StudioHttp.readJsonBody(request);
      final projectPath = body['project'] as String?;
      if (projectPath == null || projectPath.trim().isEmpty) {
        StudioHttp.respondJson(
          request.response,
          400,
          {'error': 'Missing project path'},
        );
        await request.response.close();
        return true;
      }

      final root = normalizeProjectDirectory(projectPath);
      validateFlutterProject(root);
      final force = body['force'] as bool? ?? false;
      final dryRun = body['dry_run'] as bool? ?? false;

      applyInProgress = true;
      StudioHttp.respondJson(request.response, 202, {'status': 'started'});
      await request.response.close();

      final service = SetupStudioService(applyState);
      await service.apply(
        projectRoot: root,
        planPayload: body,
        force: force,
        dryRun: dryRun,
      );
    } on Object catch (e) {
      applyState
        ..status = SetupApplyStatus.failed
        ..error = '$e'
        ..finishedAt = DateTime.now();
    } finally {
      applyInProgress = false;
    }
    return true;
  }
}
