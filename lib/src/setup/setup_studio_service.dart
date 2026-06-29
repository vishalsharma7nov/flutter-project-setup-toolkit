import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../setup_wizard.dart';
import 'setup_plan_codec.dart';
import 'setup_studio_models.dart';

class SetupStudioService {
  SetupStudioService(this.applyState);

  final SetupApplyState applyState;

  void _log(String message) {
    applyState.logs.add(message);
    stdout.writeln(message);
  }

  Future<void> apply({
    required Directory projectRoot,
    required Map<String, dynamic> planPayload,
    bool force = false,
    bool dryRun = false,
  }) async {
    applyState
      ..status = SetupApplyStatus.running
      ..startedAt = DateTime.now()
      ..finishedAt = null
      ..error = null
      ..result = null
      ..logs.clear();

    try {
      final plan = setupPlanFromGuiMap(projectRoot, planPayload);
      _log('Project: ${projectRoot.path}');
      _log('Default environment: ${plan.defaultEnvironment}');
      _log('Toolkit mode: ${plan.toolkitMode.name}');
      if (dryRun) {
        _log('Dry run — no files will be written.');
      }
      _log('');

      SetupResult? result;
      await runZoned(
        () async {
          result = await applySetupPlan(plan, force: force, dryRun: dryRun);
        },
        zoneSpecification: ZoneSpecification(
          print: (_, __, ___, line) => _log(line),
        ),
      );

      applyState
        ..status = SetupApplyStatus.succeeded
        ..result = setupResultToJson(plan, result!);
      _log('');
      _log('Setup finished successfully.');
    } on Object catch (e) {
      applyState
        ..status = SetupApplyStatus.failed
        ..error = '$e';
      _log('');
      _log('Setup failed: $e');
    } finally {
      applyState.finishedAt = DateTime.now();
    }
  }
}

Directory normalizeProjectDirectory(String projectPath) {
  return Directory(p.normalize(projectPath.trim()));
}
