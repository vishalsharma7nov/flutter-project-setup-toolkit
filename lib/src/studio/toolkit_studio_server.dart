import 'dart:async';
import 'dart:io';

import '../setup/setup_studio_service.dart';
import 'docs_studio_routes.dart';
import 'ci_studio_routes.dart';
import 'doctor_studio_routes.dart';
import 'distribution_studio_routes.dart';
import 'environment_detect.dart';
import 'feature_studio_routes.dart';
import 'quick_test_studio_routes.dart';
import 'package_studio_routes.dart';
import 'qa_studio_routes.dart';
import 'setup_studio_routes.dart';
import 'version_studio_routes.dart';
import 'studio_http.dart';
import 'studio_hub_html.dart';
import 'studio_bind.dart';
import 'studio_project_api.dart';
import 'studio_project_state.dart';

class ToolkitStudioServer {
  ToolkitStudioServer({
    Directory? projectRoot,
    required this.port,
    this.bindMode = StudioBindMode.loopback,
    StudioProjectState? projectState,
    SetupStudioRoutes? setupRoutes,
    DistributionStudioRoutes? distributionRoutes,
    FeatureStudioRoutes? featureRoutes,
    VersionStudioRoutes? versionRoutes,
    QuickTestStudioRoutes? quickTestRoutes,
    CiStudioRoutes? ciRoutes,
    QaStudioRoutes? qaRoutes,
    DocsStudioRoutes? docsRoutes,
    PackageStudioRoutes? packageRoutes,
  }) : projectState = projectState ?? StudioProjectState() {
    this.projectState.setInitial(projectRoot);
    this.setupRoutes =
        setupRoutes ?? SetupStudioRoutes(projectState: this.projectState);
    this.distributionRoutes = distributionRoutes ??
        DistributionStudioRoutes(projectState: this.projectState);
    this.featureRoutes =
        featureRoutes ?? FeatureStudioRoutes(projectState: this.projectState);
    this.versionRoutes =
        versionRoutes ?? VersionStudioRoutes(projectState: this.projectState);
    this.quickTestRoutes =
        quickTestRoutes ?? QuickTestStudioRoutes();
    this.ciRoutes = ciRoutes ?? CiStudioRoutes();
    this.qaRoutes = qaRoutes ?? QaStudioRoutes(projectState: this.projectState);
    this.docsRoutes = docsRoutes ?? DocsStudioRoutes();
    this.packageRoutes =
        packageRoutes ?? PackageStudioRoutes(projectState: this.projectState);
  }

  final StudioProjectState projectState;
  final int port;
  final StudioBindMode bindMode;
  late final SetupStudioRoutes setupRoutes;
  late final DistributionStudioRoutes distributionRoutes;
  late final FeatureStudioRoutes featureRoutes;
  late final VersionStudioRoutes versionRoutes;
  late final QuickTestStudioRoutes quickTestRoutes;
  late final CiStudioRoutes ciRoutes;
  late final QaStudioRoutes qaRoutes;
  late final DocsStudioRoutes docsRoutes;
  late final PackageStudioRoutes packageRoutes;

  HttpServer? _server;

  Future<void> start() async {
    _server = await HttpServer.bind(bindAddressFor(bindMode), port);
    _server!.listen((request) {
      unawaited(
        _handleRequest(request).catchError((Object e) {
          StudioHttp.respondJson(request.response, 500, {'error': '$e'});
          request.response.close();
        }),
      );
    });
  }

  Future<void> stop() async {
    await _server?.close(force: true);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final path = request.uri.path;

    if (request.method == 'GET' && path == '/') {
      StudioHttp.respondHtml(request.response, studioHubHtml());
      await request.response.close();
      return;
    }

    if (request.method == 'GET' && path == '/api/environment') {
      final env = await detectStudioEnvironment();
      StudioHttp.respondJson(request.response, 200, env);
      await request.response.close();
      return;
    }

    if (request.method == 'GET' && path == '/api/bootstrap') {
      StudioHttp.respondJson(
        request.response,
        200,
        studioBootstrapJson(projectState),
      );
      await request.response.close();
      return;
    }

    if (request.method == 'GET' && path == '/api/project/analyze') {
      await handleStudioProjectAnalyze(request);
      return;
    }

    if (request.method == 'POST' && path == '/api/project') {
      await handleStudioProjectPost(request, projectState);
      return;
    }

    if (request.method == 'POST' && path == '/api/project/create') {
      await handleStudioProjectCreate(request, projectState);
      return;
    }

    if ((request.method == 'POST' || request.method == 'GET') &&
        path == '/api/pick-folder') {
      await handleStudioPickFolder(request);
      return;
    }

    if (await setupRoutes.handle(request)) return;
    if (await distributionRoutes.handle(request)) return;
    if (await featureRoutes.handle(request)) return;
    if (await versionRoutes.handle(request)) return;
    if (await quickTestRoutes.handle(request)) return;
    if (await ciRoutes.handle(request)) return;
    if (await qaRoutes.handle(request)) return;
    if (await docsRoutes.handle(request)) return;
    if (await packageRoutes.handle(request)) return;
    if (await handleDoctorRoutes(request)) return;

    StudioHttp.respondJson(request.response, 404, {
      'error': 'Not found: ${request.uri.path}',
    });
    await request.response.close();
  }
}

Directory normalizeStudioProject(String projectPath) {
  return normalizeProjectDirectory(projectPath);
}
