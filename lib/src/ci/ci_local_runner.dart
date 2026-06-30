import 'dart:async';
import 'dart:io';

import '../config.dart';
import '../env/env_source.dart';
import '../flutter_tools.dart';
import 'ci_test_models.dart';
import 'ci_workflow_spec.dart';

class CiLocalRunner {
  CiLocalRunner({required this.jobState});

  final CiTestJobState jobState;

  Future<void> run({
    required Directory projectRoot,
    required CiWorkflowSpec spec,
    ToolkitConfig? config,
    EnvSourceRequest? envOverlay,
  }) async {
    jobState.status = CiTestJobStatus.running;
    jobState.runner = 'native';
    jobState.startedAt = DateTime.now();
    jobState.error = null;
    jobState.logs.clear();
    jobState.steps.clear();

    try {
      validateFlutterProject(projectRoot);
      final effectiveConfig = config ?? loadConfig(projectRoot);

      if (spec.analyze || spec.formatCheck || spec.architectureAudit) {
        await _runAnalyzeGroup(projectRoot, spec);
      }
      if (spec.androidAab) {
        await _runAndroidBuild(
          projectRoot,
          spec,
          effectiveConfig,
          envOverlay: envOverlay,
        );
      }
      if (spec.iosIpa) {
        await _runIosBuild(
          projectRoot,
          spec,
          effectiveConfig,
          envOverlay: envOverlay,
        );
      }

      jobState.status = CiTestJobStatus.passed;
    } on Object catch (e) {
      jobState.status = CiTestJobStatus.failed;
      jobState.error = '$e';
      _log('ERROR: $e');
    } finally {
      jobState.finishedAt = DateTime.now();
    }
  }

  Future<void> _runAnalyzeGroup(
    Directory projectRoot,
    CiWorkflowSpec spec,
  ) async {
    final flutter = detectFlutter();
    await _runStep('pub_get', () async {
      await _runProcess(
        projectRoot,
        flutter.executable,
        flutter.buildArgs(['pub', 'get']),
      );
    });

    if (spec.analyze) {
      await _runStep('dart_analyze', () async {
        await _runProcess(projectRoot, 'dart', ['analyze', '--fatal-infos']);
      });
      await _runStep('dart_test', () async {
        await _runProcess(projectRoot, 'dart', ['test']);
      });
    }

    if (spec.coverage) {
      await _runStep('flutter_coverage', () async {
        final flutter = detectFlutter();
        await _runProcess(
          projectRoot,
          flutter.executable,
          flutter.buildArgs(['test', '--coverage']),
        );
      });
    }

    if (spec.formatCheck) {
      await _runStep('dart_format', () async {
        await _runProcess(
          projectRoot,
          'dart',
          ['format', '--set-exit-if-changed', '.'],
        );
      });
    }

    if (spec.architectureAudit) {
      await _runStep('architecture_audit', () async {
        await _runProcess(
          projectRoot,
          'dart',
          [
            'run',
            '${spec.toolkitPackage}:architecture_audit',
            '--project',
            '.',
            '--json',
          ],
        );
      });
    }
  }

  Future<void> _runAndroidBuild(
    Directory projectRoot,
    CiWorkflowSpec spec,
    ToolkitConfig config, {
    EnvSourceRequest? envOverlay,
  }) async {
    await _runStep('android_aab', () async {
      final flutter = detectFlutter();
      final args = <String>['build', 'appbundle', '--release'];
      final envFile = await _resolveEnvFile(
        projectRoot,
        config,
        spec.defaultEnv,
        envOverlay: envOverlay,
      );
      if (envFile != null) {
        args.addAll(['--dart-define-from-file=$envFile']);
      }
      args.add('--dart-define=APP_ENV=${spec.defaultEnv}');
      final flavor = config.build.androidFlavor;
      if (flavor != null && flavor.isNotEmpty) {
        args.addAll(['--flavor', flavor]);
      }
      await _runProcess(
        projectRoot,
        flutter.executable,
        flutter.buildArgs(args),
      );
    });
  }

  Future<void> _runIosBuild(
    Directory projectRoot,
    CiWorkflowSpec spec,
    ToolkitConfig config, {
    EnvSourceRequest? envOverlay,
  }) async {
    if (!Platform.isMacOS) {
      jobState.steps.add(
        CiTestStepResult(
          id: 'ios_ipa',
          ok: true,
          skipped: true,
          message: 'iOS build skipped — requires macOS host with Xcode',
        ),
      );
      _log('SKIP ios_ipa: requires macOS host with Xcode');
      return;
    }

    await _runStep('ios_ipa', () async {
      final flutter = detectFlutter();
      final args = <String>[
        'build',
        'ipa',
        '--release',
        '--export-options-plist=ios/ExportOptions.plist',
      ];
      final envFile = await _resolveEnvFile(
        projectRoot,
        config,
        spec.defaultEnv,
        envOverlay: envOverlay,
      );
      if (envFile != null) {
        args.addAll(['--dart-define-from-file=$envFile']);
      }
      args.add('--dart-define=APP_ENV=${spec.defaultEnv}');
      final scheme = config.build.iosScheme;
      if (scheme != 'Runner') {
        args.addAll(['--scheme', scheme]);
      }
      await _runProcess(
        projectRoot,
        flutter.executable,
        flutter.buildArgs(args),
      );
    });
  }

  Future<String?> _resolveEnvFile(
    Directory projectRoot,
    ToolkitConfig config,
    String envName, {
    EnvSourceRequest? envOverlay,
  }) async {
    final resolved = resolveBuildEnvOptional(
      projectRoot: projectRoot,
      envName: envName,
      envSource: envOverlay,
    );
    if (resolved != null) {
      return resolved.file.path;
    }
    final rel = config.environments[envName];
    if (rel == null) return null;
    final file = File('${projectRoot.path}/$rel');
    return file.existsSync() ? file.path : null;
  }

  Future<void> _runStep(String id, Future<void> Function() action) async {
    final started = DateTime.now();
    _log('--- $id ---');
    try {
      await action();
      final ms = DateTime.now().difference(started).inMilliseconds;
      jobState.steps.add(CiTestStepResult(id: id, ok: true, durationMs: ms));
      _log('OK $id (${ms}ms)');
    } on Object catch (e) {
      final ms = DateTime.now().difference(started).inMilliseconds;
      jobState.steps.add(
        CiTestStepResult(id: id, ok: false, durationMs: ms, message: '$e'),
      );
      _log('FAIL $id: $e');
      rethrow;
    }
  }

  Future<void> _runProcess(
    Directory projectRoot,
    String executable,
    List<String> args,
  ) async {
    final process = await Process.start(
      executable,
      args,
      workingDirectory: projectRoot.path,
      runInShell: true,
    );
    await for (final line in process.stdout.transform(SystemEncoding().decoder)) {
      for (final part in line.split('\n')) {
        if (part.trim().isNotEmpty) _log(part);
      }
    }
    await for (final line in process.stderr.transform(SystemEncoding().decoder)) {
      for (final part in line.split('\n')) {
        if (part.trim().isNotEmpty) _log('[stderr] $part');
      }
    }
    final code = await process.exitCode;
    if (code != 0) {
      throw ProcessException(executable, args, 'exit code $code', code);
    }
  }

  void _log(String line) {
    jobState.logs.add(line);
  }
}

List<String> nativeTestStepIds(CiWorkflowSpec spec) {
  final ids = <String>[];
  if (spec.analyze || spec.formatCheck || spec.architectureAudit) {
    ids.add('pub_get');
  if (spec.analyze) {
    ids.addAll(['dart_analyze', 'dart_test']);
  }
  if (spec.coverage) ids.add('flutter_coverage');
    if (spec.formatCheck) ids.add('dart_format');
    if (spec.architectureAudit) ids.add('architecture_audit');
  }
  if (spec.androidAab) ids.add('android_aab');
  if (spec.iosIpa) ids.add('ios_ipa');
  return ids;
}
