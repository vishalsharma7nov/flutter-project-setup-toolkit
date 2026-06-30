import 'dart:io';

import 'ci_act_installer.dart';
import 'ci_test_models.dart';
import 'ci_workflow_paths.dart';

class CiActRunner {
  CiActRunner({required this.jobState});

  final CiTestJobState jobState;

  Future<void> run({
    required Directory projectRoot,
    required String workflowPath,
    String job = 'analyze',
  }) async {
    jobState.status = CiTestJobStatus.running;
    jobState.runner = 'act';
    jobState.startedAt = DateTime.now();
    jobState.error = null;
    jobState.logs.clear();
    jobState.steps.clear();

    ActProvision? provision;

    try {
      if (!Platform.isMacOS && !Platform.isLinux) {
        jobState.status = CiTestJobStatus.skipped;
        jobState.error = 'act tests require macOS or Linux';
        _log('SKIP: act local tests are not supported on this platform.');
        return;
      }

      if (!await isDockerAvailableForAct()) {
        jobState.status = CiTestJobStatus.failed;
        jobState.error = 'Docker is required for act tests';
        _log('Docker is not running. Start Docker Desktop and retry.');
        return;
      }

      if (workflowPath.contains('flutter-release') &&
          (job == 'ios' || job.contains('ios'))) {
        jobState.status = CiTestJobStatus.skipped;
        jobState.error = 'iOS job requires macOS host — use native test on Mac';
        _log('SKIP: macos-latest jobs cannot run in act Docker on most hosts.');
        _log('Hint: act -j ios -P macos-latest=-self-hosted (self-hosted runner)');
        return;
      }

      final fullWorkflow = '${projectRoot.path}/$workflowPath';
      if (!File(fullWorkflow).existsSync()) {
        jobState.status = CiTestJobStatus.failed;
        jobState.error = 'Workflow file not found: $workflowPath';
        return;
      }

      provision = await provisionAct(log: _log);

      final cmd = [
        'push',
        '-W',
        workflowPath,
        '-j',
        job,
        '--container-architecture',
        'linux/amd64',
      ];
      _log('Running: act ${cmd.join(' ')}');

      final started = DateTime.now();
      final process = await Process.start(
        provision.binaryPath,
        cmd,
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
      final ms = DateTime.now().difference(started).inMilliseconds;
      if (code == 0) {
        jobState.status = CiTestJobStatus.passed;
        jobState.steps.add(
          CiTestStepResult(id: 'act_$job', ok: true, durationMs: ms),
        );
      } else {
        jobState.status = CiTestJobStatus.failed;
        jobState.error = 'act exited with code $code';
        jobState.steps.add(
          CiTestStepResult(
            id: 'act_$job',
            ok: false,
            durationMs: ms,
            message: jobState.error,
          ),
        );
      }
    } on Object catch (e) {
      jobState.status = CiTestJobStatus.failed;
      jobState.error = '$e';
      _log('ERROR: $e');
    } finally {
      if (provision != null) {
        _log('Removing temporary act install…');
        await removeActProvision(provision);
      }
      jobState.finishedAt = DateTime.now();
    }
  }

  String suggestedWorkflowPath({required bool split}) {
    return split ? CiWorkflowPaths.ciWorkflow : CiWorkflowPaths.releaseWorkflow;
  }

  void _log(String line) => jobState.logs.add(line);
}
