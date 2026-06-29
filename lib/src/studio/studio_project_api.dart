import 'dart:io';

import '../config.dart';
import '../setup/setup_studio_service.dart';
import 'environment_detect.dart';
import 'flutter_project_structure.dart';
import 'studio_http.dart';
import 'studio_project_state.dart';

Future<void> handleStudioProjectAnalyze(
  HttpRequest request,
) async {
  final projectPath = request.uri.queryParameters['path'];
  if (projectPath == null || projectPath.trim().isEmpty) {
    StudioHttp.respondJson(
      request.response,
      400,
      {'error': 'Missing path query parameter'},
    );
    await request.response.close();
    return;
  }

  try {
    final root = normalizeProjectDirectory(projectPath);
    if (!root.existsSync()) {
      throw StateError('Project folder does not exist: ${root.path}');
    }
    final analysis = analyzeFlutterProjectStructure(root);
    final env = await detectStudioEnvironment();
    StudioHttp.respondJson(request.response, 200, {
      ...analysis.toJson(),
      'flutter_installed': env['flutter']?['installed'] == true,
    });
  } on Object catch (e) {
    StudioHttp.respondJson(request.response, 400, {'error': '$e'});
  }
  await request.response.close();
}

Future<void> handleStudioProjectPost(
  HttpRequest request,
  StudioProjectState projectState,
) async {
  Map<String, dynamic> payload;
  try {
    payload = await StudioHttp.readJsonBody(request);
  } on FormatException catch (e) {
    StudioHttp.respondJson(request.response, 400, {
      'error': 'Invalid JSON body: $e',
    });
    await request.response.close();
    return;
  }

  final projectPath = payload['project'] as String?;
  final repair = payload['repair'] as bool? ?? false;
  if (projectPath == null || projectPath.trim().isEmpty) {
    StudioHttp.respondJson(
      request.response,
      400,
      {'error': 'Missing project path'},
    );
    await request.response.close();
    return;
  }

  try {
    var root = normalizeProjectDirectory(projectPath);
    FlutterProjectRepairResult? repairResult;
    var analysis = analyzeFlutterProjectStructure(root);

    if (!analysis.compatible) {
      if (repair && analysis.canRepair) {
        repairResult = await repairFlutterProjectStructure(root);
        analysis = repairResult.analysis;
        root = Directory(analysis.projectPath);
      } else {
        StudioHttp.respondJson(request.response, 400, {
          'error': 'Project is not a compatible Flutter structure',
          'analysis': analysis.toJson(),
          'can_repair': analysis.canRepair,
        });
        await request.response.close();
        return;
      }
    }

    if (!analysis.compatible) {
      throw StateError(
        'Project structure is still incomplete after repair: '
        '${analysis.issues.join(', ')}',
      );
    }

    validateFlutterSdkProject(root);

    projectState.setRoot(root);
    final env = await detectStudioEnvironment();
    StudioHttp.respondJson(request.response, 200, {
      'project_path': root.path,
      'is_flutter_project': true,
      'analysis': analysis.toJson(),
      'repair': repairResult?.toJson(),
      'environment': env,
    });
  } on Object catch (e) {
    StudioHttp.respondJson(request.response, 400, {'error': '$e'});
  }
  await request.response.close();
}

Future<void> handleStudioProjectCreate(
  HttpRequest request,
  StudioProjectState projectState,
) async {
  Map<String, dynamic> payload;
  try {
    payload = await StudioHttp.readJsonBody(request);
  } on FormatException catch (e) {
    StudioHttp.respondJson(request.response, 400, {
      'error': 'Invalid JSON body: $e',
    });
    await request.response.close();
    return;
  }

  final parentPath = payload['parent_path'] as String?;
  final projectName = payload['project_name'] as String?;

  if (parentPath == null || parentPath.trim().isEmpty) {
    StudioHttp.respondJson(
      request.response,
      400,
      {'error': 'Missing parent_path'},
    );
    await request.response.close();
    return;
  }
  if (projectName == null || projectName.trim().isEmpty) {
    StudioHttp.respondJson(
      request.response,
      400,
      {'error': 'Missing project_name'},
    );
    await request.response.close();
    return;
  }

  try {
    final env = await detectStudioEnvironment();
    if (env['flutter']?['installed'] != true) {
      StudioHttp.respondJson(request.response, 400, {
        'error':
            'Flutter is not installed on this device. Install Flutter before creating a project.',
        'environment': env,
      });
      await request.response.close();
      return;
    }

    final created = await createFlutterProject(
      parentDirectory: Directory(parentPath.trim()),
      projectName: projectName.trim(),
    );
    final analysis = analyzeFlutterProjectStructure(created);
    projectState.setRoot(created);
    StudioHttp.respondJson(request.response, 200, {
      'project_path': created.path,
      'project_name': analysis.projectName,
      'analysis': analysis.toJson(),
      'created': true,
      'environment': env,
    });
  } on Object catch (e) {
    StudioHttp.respondJson(request.response, 400, {'error': '$e'});
  }
  await request.response.close();
}

Map<String, dynamic> studioBootstrapJson(StudioProjectState projectState) {
  return {
    'project_path': projectState.path,
    'project_required': true,
  };
}
