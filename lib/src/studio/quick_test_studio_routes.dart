import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../env/env_source.dart';
import '../quick_test/quick_test_models.dart';
import '../quick_test/quick_test_source.dart';
import '../quick_test/quick_test_pipeline.dart';
import '../quick_test/quick_test_ui_html.dart';
import 'studio_http.dart';
import 'studio_nav.dart';

class QuickTestStudioRoutes {
  factory QuickTestStudioRoutes({QuickTestPipeline? pipeline}) {
    final jobState = pipeline?.jobState ?? QuickTestJobState();
    return QuickTestStudioRoutes._(
      jobState: jobState,
      pipeline: pipeline ?? QuickTestPipeline(jobState),
    );
  }

  QuickTestStudioRoutes._({
    required this.jobState,
    required this.pipeline,
  });

  final QuickTestJobState jobState;
  final QuickTestPipeline pipeline;
  bool runInProgress = false;

  Future<bool> handle(HttpRequest request) async {
    final path = request.uri.path;

    if (request.method == 'GET' && path == '/quick-test') {
      StudioHttp.respondHtml(
        request.response,
        wrapStudioPage(quickTestStudioHtml()),
      );
      await request.response.close();
      return true;
    }

    if (request.method == 'POST' && path == '/api/quick-test/preflight') {
      return _handlePreflight(request);
    }

    if (request.method == 'POST' && path == '/api/quick-test/run') {
      return _handleRun(request);
    }

    if (request.method == 'GET' && path == '/api/quick-test/status') {
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

    if (request.method == 'GET' && path == '/api/quick-test/artifacts/download') {
      return _handleArtifactDownload(request);
    }

    if (request.method == 'POST' && path == '/api/quick-test/cancel') {
      await pipeline.cancel();
      runInProgress = false;
      StudioHttp.respondJson(request.response, 200, {'status': 'cancelled'});
      await request.response.close();
      return true;
    }

    return false;
  }

  Future<bool> _handleArtifactDownload(HttpRequest request) async {
    final artifactPath = request.uri.queryParameters['path'];
    if (artifactPath == null || artifactPath.trim().isEmpty) {
      StudioHttp.respondJson(request.response, 400, {'error': 'path is required'});
      await request.response.close();
      return true;
    }

    if (!quickTestArtifactPathAllowed(artifactPath, jobState.artifactPaths)) {
      StudioHttp.respondJson(request.response, 403, {
        'error': 'Artifact not available for download',
      });
      await request.response.close();
      return true;
    }

    final file = File(artifactPath);
    final filename = p.basename(file.path);
    request.response.headers.set(
      'Content-Type',
      quickTestArtifactContentType(file.path),
    );
    request.response.headers.set(
      'Content-Disposition',
      'attachment; filename="${filename.replaceAll('"', '')}"',
    );
    request.response.headers.set('Content-Length', '${await file.length()}');
    request.response.statusCode = HttpStatus.ok;
    await request.response.addStream(file.openRead());
    await request.response.close();
    return true;
  }

  Future<bool> _handlePreflight(HttpRequest request) async {
    try {
      final payload = await StudioHttp.readJsonBody(request);
      final sourceJson = payload['source'] as Map<String, dynamic>?;
      if (sourceJson == null) {
        throw ArgumentError('source is required');
      }
      final env = payload['env'] as String? ?? 'dev';
      EnvSourceRequest? envSource;
      if (payload['env_source'] != null) {
        envSource = EnvSourceRequest.fromJson(
          payload['env_source'] as Map<String, dynamic>,
        );
      }
      final source = QuickTestSource.fromJson(sourceJson);
      final result = await runQuickTestPreflight(
        source: source,
        envName: env,
        envSource: envSource,
      );
      StudioHttp.respondJson(request.response, 200, result);
    } on Object catch (e) {
      StudioHttp.respondJson(request.response, 400, {'error': '$e'});
    }
    await request.response.close();
    return true;
  }

  Future<bool> _handleRun(HttpRequest request) async {
    if (runInProgress) {
      StudioHttp.respondJson(
        request.response,
        409,
        {'error': 'A quick test is already running'},
      );
      await request.response.close();
      return true;
    }

    try {
      final payload = await StudioHttp.readJsonBody(request);
      final sourceJson = payload['source'] as Map<String, dynamic>?;
      if (sourceJson == null) {
        throw ArgumentError('source is required');
      }
      final env = payload['env'] as String? ?? 'dev';
      EnvSourceRequest? envSource;
      if (payload['env_source'] != null) {
        envSource = EnvSourceRequest.fromJson(
          payload['env_source'] as Map<String, dynamic>,
        );
      }
      final source = QuickTestSource.fromJson(sourceJson);
      final options = QuickTestRunOptions.fromJson(payload);

      runInProgress = true;
      unawaited(
        pipeline
            .run(
              source: source,
              envName: env,
              envSource: envSource,
              options: options,
            )
            .whenComplete(() => runInProgress = false),
      );

      StudioHttp.respondJson(request.response, 202, {'status': 'started'});
    } on Object catch (e) {
      runInProgress = false;
      StudioHttp.respondJson(request.response, 400, {'error': '$e'});
    }
    await request.response.close();
    return true;
  }
}
