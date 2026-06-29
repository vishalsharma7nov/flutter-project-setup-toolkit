import 'dart:io';

import 'package:path/path.dart' as p;

import '../config.dart';
import '../config_file.dart';
import '../distribution/distribution_build_service.dart';
import '../distribution/distribution_models.dart';
import '../distribution/distribution_preflight.dart';
import '../distribution/distribution_project_resolver.dart';
import '../distribution/distribution_ui_html.dart';
import '../env/env_source.dart';
import '../flutter_tools.dart';
import '../git/git_remote_source.dart';
import 'studio_http.dart';
import 'studio_nav.dart';
import 'studio_project_state.dart';

class DistributionStudioRoutes {
  factory DistributionStudioRoutes({
    StudioProjectState? projectState,
    DistributionBuildService? buildService,
  }) {
    final jobState = buildService?.jobState ?? DistributionJobState();
    return DistributionStudioRoutes._(
      projectState: projectState ?? StudioProjectState(),
      jobState: jobState,
      buildService: buildService ?? DistributionBuildService(jobState),
    );
  }

  DistributionStudioRoutes._({
    required this.projectState,
    required this.jobState,
    required this.buildService,
  });

  final StudioProjectState projectState;
  final DistributionJobState jobState;
  final DistributionBuildService buildService;
  bool buildInProgress = false;

  Future<bool> handle(HttpRequest request) async {
    final path = request.uri.path;

    if (request.method == 'GET' && path == '/build') {
      StudioHttp.respondHtml(
        request.response,
        wrapStudioPage(distributionStudioHtml()),
      );
      await request.response.close();
      return true;
    }

    if (request.method == 'GET' &&
        (path == '/api/project' || path == '/api/distribution/project')) {
      return _handleProject(request);
    }

    if (request.method == 'GET' &&
        (path == '/api/preflight' || path == '/api/distribution/preflight')) {
      return _handlePreflight(request);
    }

    if (request.method == 'POST' &&
        (path == '/api/distribution/repo/preflight' ||
            path == '/api/repo/preflight')) {
      return _handleRepoPreflight(request);
    }

    if (request.method == 'GET' &&
        (path == '/api/status' || path == '/api/distribution/status')) {
      final offset =
          int.tryParse(request.uri.queryParameters['offset'] ?? '0') ?? 0;
      StudioHttp.respondJson(
        request.response,
        200,
        jobState.toJson(logOffset: offset),
      );
      await request.response.close();
      return true;
    }

    if (request.method == 'POST' &&
        (path == '/api/build/cancel' || path == '/api/distribution/cancel')) {
      await buildService.cancel();
      StudioHttp.respondJson(request.response, 200, {'status': 'cancelled'});
      await request.response.close();
      return true;
    }

    if (request.method == 'GET' &&
        (path == '/api/distribution/config' || path == '/api/config')) {
      return _handleConfigGet(request);
    }

    if (request.method == 'POST' &&
        (path == '/api/distribution/config' || path == '/api/config')) {
      return _handleConfigSave(request);
    }

    if (request.method == 'POST' &&
        (path == '/api/build' || path == '/api/distribution/build')) {
      return _handleBuild(request);
    }

    return false;
  }

  Future<bool> _handleProject(HttpRequest request) async {
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
      final root = Directory(p.normalize(projectPath.trim()));
      final info = await loadDistributionProjectInfoAsync(root);
      StudioHttp.respondJson(request.response, 200, info.toJson());
    } on Object catch (e) {
      StudioHttp.respondJson(request.response, 400, {'error': '$e'});
    }
    await request.response.close();
    return true;
  }

  Future<bool> _handlePreflight(HttpRequest request) async {
    final projectPath = request.uri.queryParameters['path'];
    final env = request.uri.queryParameters['env'] ?? 'dev';
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
      final root = Directory(p.normalize(projectPath.trim()));
      final result = distributionPreflightJson(
        projectRoot: root,
        envName: env,
        androidFlavor: request.uri.queryParameters['android_flavor'],
        iosFlavor: request.uri.queryParameters['ios_flavor'],
        iosScheme: request.uri.queryParameters['ios_scheme'],
      );
      StudioHttp.respondJson(request.response, 200, result);
    } on Object catch (e) {
      StudioHttp.respondJson(request.response, 400, {'error': '$e'});
    }
    await request.response.close();
    return true;
  }

  Future<bool> _handleRepoPreflight(HttpRequest request) async {
    try {
      final payload = await StudioHttp.readJsonBody(request);
      final sourceJson = payload['source'] as Map<String, dynamic>?;
      if (sourceJson == null) {
        throw ArgumentError('source is required');
      }
      final env = payload['env'] as String? ?? 'dev';
      final source = GitRemoteSource.fromJson(sourceJson);
      final result = await runRepoPreflight(
        source: source,
        envName: env,
        androidFlavor: payload['android_flavor'] as String?,
        iosFlavor: payload['ios_flavor'] as String?,
        iosScheme: payload['ios_scheme'] as String?,
      );
      StudioHttp.respondJson(request.response, 200, result);
    } on Object catch (e) {
      StudioHttp.respondJson(request.response, 400, {'error': '$e'});
    }
    await request.response.close();
    return true;
  }

  Future<bool> _handleConfigGet(HttpRequest request) async {
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
      final root = Directory(p.normalize(projectPath.trim()));
      validateFlutterProject(root);
      StudioHttp.respondJson(
        request.response,
        200,
        releaseToolkitConfigForApi(root),
      );
    } on Object catch (e) {
      StudioHttp.respondJson(request.response, 400, {'error': '$e'});
    }
    await request.response.close();
    return true;
  }

  Future<bool> _handleConfigSave(HttpRequest request) async {
    try {
      final payload = await StudioHttp.readJsonBody(request);
      final projectPath = payload['project'] as String?;
      if (projectPath == null || projectPath.trim().isEmpty) {
        throw ArgumentError('project is required');
      }
      final root = Directory(p.normalize(projectPath.trim()));
      final patch = payload['patch'] as Map<String, dynamic>? ??
          distributionConfigPatchFromUi(
            environments: Map<String, String>.from(
              (payload['environments'] as Map?)?.cast<String, String>() ?? {},
            ),
            defaultEnvironment: payload['default_environment'] as String?,
            envPathForSelected: payload['env_path'] as String?,
            selectedEnv: payload['env'] as String?,
            androidFlavor: payload['android_flavor'] as String?,
            iosFlavor: payload['ios_flavor'] as String?,
            iosScheme: payload['ios_scheme'] as String?,
            openOrganizer: payload['open_organizer'] as bool?,
          );
      final result = saveReleaseToolkitConfigPatch(
        projectRoot: root,
        patch: patch,
      );
      StudioHttp.respondJson(request.response, 200, result);
    } on Object catch (e) {
      StudioHttp.respondJson(request.response, 400, {'error': '$e'});
    }
    await request.response.close();
    return true;
  }

  Future<bool> _handleBuild(HttpRequest request) async {
    if (buildInProgress) {
      StudioHttp.respondJson(
        request.response,
        409,
        {'error': 'A build is already running'},
      );
      await request.response.close();
      return true;
    }

    try {
      detectFlutter();
    } on Object catch (e) {
      StudioHttp.respondJson(request.response, 503, {
        'error': '$e',
        'hint': 'Install Flutter to build APK/IPA',
      });
      await request.response.close();
      return true;
    }

    final payload = await StudioHttp.readJsonBody(request);
    final projectPath = payload['project'] as String?;
    final sourceJson = payload['source'] as Map<String, dynamic>?;
    final env = payload['env'] as String?;
    final targetName = payload['target'] as String?;

    if (env == null || targetName == null) {
      StudioHttp.respondJson(request.response, 400, {
        'error': 'Required fields: env, target (and project or source)',
      });
      await request.response.close();
      return true;
    }

    if (projectPath == null && sourceJson == null) {
      StudioHttp.respondJson(request.response, 400, {
        'error': 'Provide project (local path) or source (git)',
      });
      await request.response.close();
      return true;
    }

    final target = _parseTarget(targetName);
    if (target == null) {
      StudioHttp.respondJson(
        request.response,
        400,
        {'error': 'Invalid target: $targetName'},
      );
      await request.response.close();
      return true;
    }

    if ((target == DistributionTarget.iosTestFlight ||
            target == DistributionTarget.both) &&
        !Platform.isMacOS) {
      StudioHttp.respondJson(request.response, 400, {
        'error': 'iOS TestFlight builds require macOS with Xcode.',
      });
      await request.response.close();
      return true;
    }

    EnvSourceRequest? envSource;
    if (payload['env_source'] is Map<String, dynamic>) {
      envSource = EnvSourceRequest.fromJson(
        payload['env_source'] as Map<String, dynamic>,
      );
    }

    try {
      final resolved = await resolveDistributionProject(
        projectPath: projectPath,
        source: sourceJson,
      );
      buildInProgress = true;
      StudioHttp.respondJson(request.response, 202, {'status': 'started'});
      await request.response.close();

      Map<String, dynamic>? configPatch;
      if (payload['save_config'] == true || payload['config_patch'] != null) {
        configPatch = payload['config_patch'] as Map<String, dynamic>? ??
            distributionConfigPatchFromUi(
              environments: Map<String, String>.from(
                (payload['environments'] as Map?)?.cast<String, String>() ??
                    loadConfig(resolved.root).environments,
              ),
              defaultEnvironment: payload['default_environment'] as String?,
              envPathForSelected: payload['env_path'] as String?,
              selectedEnv: env,
              androidFlavor: payload['android_flavor'] as String?,
              iosFlavor: payload['ios_flavor'] as String?,
              iosScheme: payload['ios_scheme'] as String?,
              openOrganizer: payload['open_organizer'] as bool?,
            );
      }

      await buildService.run(
        projectRoot: resolved.root,
        target: target,
        envName: env,
        androidFlavor: payload['android_flavor'] as String?,
        iosFlavor: payload['ios_flavor'] as String?,
        iosScheme: payload['ios_scheme'] as String?,
        envSource: envSource,
        configPatch: configPatch,
      );
    } on Object catch (e) {
      jobState
        ..status = DistributionJobStatus.failed
        ..error = '$e'
        ..finishedAt = DateTime.now();
    } finally {
      buildInProgress = false;
    }
    return true;
  }
}

DistributionTarget? _parseTarget(String name) {
  for (final target in DistributionTarget.values) {
    if (target.name == name) return target;
  }
  return null;
}
