import 'dart:io';

import 'package:path/path.dart' as p;

import '../config.dart';
import '../packages/package_studio_ui_html.dart';
import '../packages/pub_package_service.dart';
import 'studio_http.dart';
import 'studio_nav.dart';
import 'studio_project_state.dart';

class PackageStudioRoutes {
  PackageStudioRoutes({
    StudioProjectState? projectState,
    PubPackageService? service,
  })  : projectState = projectState ?? StudioProjectState(),
        service = service ?? PubPackageService();

  final StudioProjectState projectState;
  final PubPackageService service;

  Future<bool> handle(HttpRequest request) async {
    final path = request.uri.path;

    if (request.method == 'GET' && path == '/packages') {
      StudioHttp.respondHtml(
        request.response,
        wrapStudioPage(packageStudioHtml()),
      );
      await request.response.close();
      return true;
    }

    if (request.method == 'GET' && path == '/api/packages/search') {
      return _handleSearch(request);
    }

    if (request.method == 'GET' && path == '/api/packages/resolve') {
      return _handleResolve(request);
    }

    if (request.method == 'POST' && path == '/api/packages/git/validate') {
      return _handleGitValidate(request);
    }

    if (request.method == 'GET' && path == '/api/packages/detail') {
      return _handleDetail(request);
    }

    if (request.method == 'POST' && path == '/api/packages/install') {
      return _handleInstall(request);
    }

    return false;
  }

  Future<bool> _handleSearch(HttpRequest request) async {
    try {
      final query = request.uri.queryParameters['q'] ?? '';
      final page = int.tryParse(request.uri.queryParameters['page'] ?? '') ?? 1;
      final data = await service.searchPackages(query, page: page);
      StudioHttp.respondJson(request.response, 200, data);
    } on Object catch (e) {
      StudioHttp.respondJson(request.response, 400, {'error': '$e'});
    }
    await request.response.close();
    return true;
  }

  Future<bool> _handleResolve(HttpRequest request) async {
    try {
      final input = request.uri.queryParameters['input'];
      if (input == null || input.trim().isEmpty) {
        throw ArgumentError('input is required');
      }
      final parsed = resolvePackageInput(input);
      if (parsed == null) {
        StudioHttp.respondJson(request.response, 400, {
          'error': 'Could not parse package name, pub.dev URL, or Git URL',
        });
      } else {
        StudioHttp.respondJson(request.response, 200, parsed);
      }
    } on Object catch (e) {
      StudioHttp.respondJson(request.response, 400, {'error': '$e'});
    }
    await request.response.close();
    return true;
  }

  Future<bool> _handleDetail(HttpRequest request) async {
    try {
      final name = request.uri.queryParameters['name'];
      if (name == null || name.trim().isEmpty) {
        throw ArgumentError('name is required');
      }
      Directory? root;
      final projectPath =
          request.uri.queryParameters['project'] ?? projectState.path;
      if (projectPath != null && projectPath.trim().isNotEmpty) {
        root = Directory(p.normalize(projectPath.trim()));
        validateFlutterProject(root);
      }
      final detail = await service.fetchPackageDetail(
        name.trim(),
        projectRoot: root,
      );
      StudioHttp.respondJson(request.response, 200, detail.toJson());
    } on Object catch (e) {
      StudioHttp.respondJson(request.response, 400, {'error': '$e'});
    }
    await request.response.close();
    return true;
  }

  Future<bool> _handleGitValidate(HttpRequest request) async {
    try {
      final payload = await StudioHttp.readJsonBody(request);
      final gitUrl = payload['git_url'] as String?;
      if (gitUrl == null || gitUrl.trim().isEmpty) {
        throw ArgumentError('git_url is required');
      }
      final report = await service.validateGitPackage(
        gitUrl: gitUrl.trim(),
        gitRef: (payload['git_ref'] as String?)?.trim() ?? 'main',
        gitPath: (payload['git_path'] as String?)?.trim() ?? '',
      );
      StudioHttp.respondJson(request.response, 200, report.toJson());
    } on Object catch (e) {
      StudioHttp.respondJson(request.response, 400, {'error': '$e'});
    }
    await request.response.close();
    return true;
  }

  Future<bool> _handleInstall(HttpRequest request) async {
    try {
      final payload = await StudioHttp.readJsonBody(request);
      final projectPath = payload['project'] as String?;
      final name = payload['name'] as String?;
      if (projectPath == null || projectPath.trim().isEmpty) {
        throw ArgumentError('project is required');
      }
      if (name == null || name.trim().isEmpty) {
        throw ArgumentError('name is required');
      }
      final root = Directory(p.normalize(projectPath.trim()));
      validateFlutterProject(root);
      final source = payload['source'] as String? ?? 'pub';
      final dev = payload['dev'] == true;

      if (source == 'git') {
        final gitUrl = payload['git_url'] as String?;
        if (gitUrl == null || gitUrl.trim().isEmpty) {
          throw ArgumentError('git_url is required for git install');
        }
        final result = await service.installGitPackage(
          root,
          packageName: name.trim(),
          gitUrl: gitUrl.trim(),
          gitRef: (payload['git_ref'] as String?)?.trim(),
          gitPath: (payload['git_path'] as String?)?.trim(),
          dev: dev,
          skipValidation: payload['skip_validation'] == true,
        );
        StudioHttp.respondJson(request.response, 200, result.toJson());
        await request.response.close();
        return true;
      }

      final version = payload['version'] as String?;
      final result = await service.installPackage(
        root,
        name: name.trim(),
        version: version?.trim().isEmpty == true ? null : version?.trim(),
        dev: dev,
      );
      StudioHttp.respondJson(request.response, 200, result.toJson());
    } on Object catch (e) {
      StudioHttp.respondJson(request.response, 400, {'error': '$e'});
    }
    await request.response.close();
    return true;
  }
}
