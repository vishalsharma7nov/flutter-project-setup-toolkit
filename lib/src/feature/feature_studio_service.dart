import 'dart:async';
import 'dart:io';

import '../api/api_config.dart';
import '../architecture/architecture_config.dart';
import '../config.dart';
import '../feature_scaffold.dart';
import '../models.dart';
import '../state_management.dart';
import 'feature_studio_models.dart';

class FeatureStudioService {
  FeatureStudioService(this.applyState);

  final FeatureApplyState applyState;

  void _log(String message) {
    applyState.logs.add(message);
    stdout.writeln(message);
  }

  Future<void> apply({
    required Directory projectRoot,
    required String featureName,
    required String basePath,
    required StateManagement stateManagement,
    bool dryRun = false,
    ArchitectureConfig? architecture,
    ApiConfig? api,
  }) async {
    applyState
      ..status = FeatureApplyStatus.running
      ..startedAt = DateTime.now()
      ..finishedAt = null
      ..error = null
      ..result = null
      ..logs.clear();

    try {
      _log('Project: ${projectRoot.path}');
      _log('Feature: $featureName');
      _log('Base path: $basePath');
      _log('State management: ${stateManagement.name}');
      if (dryRun) _log('Dry run — no files will be written.');
      if (architecture != null) {
        _log('Architecture preset: ${architecture.preset.label}');
      }
      if (api != null) {
        _log('API protocol: ${api.protocol.id}');
      }
      _log('');

      FeatureScaffoldResult? result;
      final projectConfig = loadConfig(projectRoot);
      final arch = architecture ?? projectConfig.architecture;
      final apiConfig = api ?? projectConfig.api;
      await runZoned(
        () async {
          if (!dryRun && stateManagement != StateManagement.none) {
            final packageResult = await applyStateManagementPackages(
              projectRoot,
              stateManagement,
            );
            if (packageResult.applied && packageResult.detail != null) {
              _log(packageResult.detail!);
            } else if (packageResult.error != null) {
              throw StateError(packageResult.error!);
            }
          }

          result = await scaffoldFeature(
            projectRoot: projectRoot,
            featureName: featureName,
            basePath: basePath,
            stateManagement: stateManagement,
            architecture: arch,
            api: apiConfig,
            dryRun: dryRun,
          );
        },
        zoneSpecification: ZoneSpecification(
          print: (_, __, ___, line) => _log(line),
        ),
      );

      applyState
        ..status = FeatureApplyStatus.succeeded
        ..result = {
          'feature_name': result!.featureName,
          'root_path': result!.rootPath,
          'file_prefix': result!.filePrefix,
          'created_paths': result!.createdPaths,
          'dry_run': result!.dryRun,
        };
      _log('');
      _log('Feature scaffold finished successfully.');
    } on Object catch (e) {
      applyState
        ..status = FeatureApplyStatus.failed
        ..error = '$e';
      _log('');
      _log('Feature scaffold failed: $e');
    } finally {
      applyState.finishedAt = DateTime.now();
    }
  }
}

// previewFeatureScaffold and detectFeatureProject are exported from feature_scaffold.dart
