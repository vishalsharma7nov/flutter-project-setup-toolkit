import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/ci/ci_devops_requirements.dart';
import 'package:flutter_project_setup_toolkit/src/ci/ci_act_installer.dart';
import 'package:flutter_project_setup_toolkit/src/ci/ci_readiness.dart';
import 'package:flutter_project_setup_toolkit/src/ci/ci_local_runner.dart';
import 'package:flutter_project_setup_toolkit/src/ci/ci_publish_service.dart';
import 'package:flutter_project_setup_toolkit/src/ci/ci_test_models.dart';
import 'package:flutter_project_setup_toolkit/src/ci/ci_workflow_spec.dart';
import 'package:flutter_project_setup_toolkit/src/ci/ci_yaml_validate.dart';
import 'package:flutter_project_setup_toolkit/src/ci/github_actions_template.dart';
import 'package:flutter_project_setup_toolkit/src/config.dart';
import 'package:flutter_project_setup_toolkit/src/models.dart';
import 'package:test/test.dart';

ToolkitConfig _sampleConfig() {
  return ToolkitConfig(
    projectRoot: Directory.systemTemp,
    environments: const {'dev': '.env.dev', 'prod': '.env.prod'},
    versionKeys: defaultVersionKeys,
    mainDartEnvRules: const [],
    build: const BuildConfig(androidFlavor: 'prod'),
    defaultEnvironment: 'dev',
  );
}

void main() {
  group('CiWorkflowSpec', () {
    test('JSON round-trip preserves toggles', () {
      final spec = CiWorkflowSpec.fromPreset(CiWorkflowPreset.full).copyWith(
        androidAab: false,
        formatCheck: true,
      );
      final restored = CiWorkflowSpec.fromJson(spec.toJson());
      expect(restored.androidAab, isFalse);
      expect(restored.formatCheck, isTrue);
      expect(restored.preset, CiWorkflowPreset.full);
    });

    test('presets configure expected jobs', () {
      final pr = CiWorkflowSpec.fromPreset(CiWorkflowPreset.prChecks);
      expect(pr.androidAab, isFalse);
      expect(pr.onPullRequest, isTrue);
      expect(pr.onPush, isFalse);

      final release = CiWorkflowSpec.fromPreset(CiWorkflowPreset.release);
      expect(release.androidAab, isTrue);
      expect(release.onPullRequest, isFalse);
    });
  });

  group('generateWorkflowFiles', () {
    test('split full preset produces CI and release files', () {
      final spec = CiWorkflowSpec.fromPreset(CiWorkflowPreset.full);
      final files = generateWorkflowFiles(spec: spec, config: _sampleConfig());
      expect(files.keys, contains('.github/workflows/flutter-ci.yml'));
      expect(files.keys, contains('.github/workflows/flutter-release.yml'));
    });

    test('pr checks preset is valid YAML', () {
      final spec = CiWorkflowSpec.fromPreset(CiWorkflowPreset.prChecks);
      final files = generateWorkflowFiles(spec: spec, config: _sampleConfig());
      for (final entry in files.entries) {
        expect(validateWorkflowYaml(entry.value), isNull, reason: entry.key);
        expect(entry.value, contains('dart analyze'));
      }
    });

    test('release preset includes Java 17 and caches', () {
      final spec = CiWorkflowSpec.fromPreset(CiWorkflowPreset.release);
      final files = generateWorkflowFiles(spec: spec, config: _sampleConfig());
      final yaml = files.values.first;
      expect(yaml, contains("java-version: '17'"));
      expect(yaml, contains('actions/cache@v4'));
      expect(yaml, contains('concurrency:'));
    });

    test('format check included when enabled', () {
      final spec = CiWorkflowSpec.fromPreset(CiWorkflowPreset.full);
      final files = generateWorkflowFiles(spec: spec, config: _sampleConfig());
      expect(
        files['.github/workflows/flutter-ci.yml'],
        contains('dart format --set-exit-if-changed'),
      );
    });

    test('path filters add dorny/paths-filter job', () {
      final spec = CiWorkflowSpec.fromPreset(CiWorkflowPreset.prChecks).copyWith(
        pathFilters: true,
      );
      final files = generateWorkflowFiles(spec: spec, config: _sampleConfig());
      expect(files.values.first, contains('dorny/paths-filter@v3'));
    });

    test('coverage step when enabled', () {
      final spec = CiWorkflowSpec.fromPreset(CiWorkflowPreset.prChecks).copyWith(
        coverage: true,
      );
      final files = generateWorkflowFiles(spec: spec, config: _sampleConfig());
      expect(files.values.first, contains('flutter test --coverage'));
    });

    test('firebase fastlane stub includes firebase lane', () {
      final stub = generateFastlaneStub(firebase: true);
      expect(stub, contains('lane :firebase'));
    });
  });

  group('DevOps minimal setup', () {
    test('minimal ready when required tools present', () {
      final report = evaluateDevOpsSetup(
        projectRoot: Directory.systemTemp,
        spec: CiWorkflowSpec.fromPreset(CiWorkflowPreset.prChecks),
        hasToolkitConfig: true,
        dartInstalled: true,
        flutterInstalled: true,
        gitInstalled: true,
        ghInstalled: true,
        ghAuthenticated: true,
        githubRemoteOk: true,
        githubRemoteLabel: 'org/repo',
        macosHost: true,
        xcodeInstalled: true,
        dockerAvailable: false,
      );
      expect(report.minimalReady, isTrue);
      expect(report.publishReady, isTrue);
    });

    test('omits docker when act studio disabled', () {
      final report = evaluateDevOpsSetup(
        projectRoot: Directory.systemTemp,
        spec: CiWorkflowSpec.fromPreset(CiWorkflowPreset.prChecks),
        hasToolkitConfig: true,
        dartInstalled: true,
        flutterInstalled: true,
        gitInstalled: true,
        ghInstalled: true,
        ghAuthenticated: true,
        githubRemoteOk: true,
        githubRemoteLabel: 'org/repo',
        macosHost: true,
        xcodeInstalled: true,
        dockerAvailable: true,
      );
      expect(report.minimalReady, isTrue);
      expect(
        report.requirements.any((r) => r.id == 'docker'),
        isFalse,
      );
    });

    test('publish not ready without gh auth', () {
      final report = evaluateDevOpsSetup(
        projectRoot: Directory.systemTemp,
        spec: CiWorkflowSpec.fromPreset(CiWorkflowPreset.prChecks),
        hasToolkitConfig: true,
        dartInstalled: true,
        flutterInstalled: true,
        gitInstalled: true,
        ghInstalled: true,
        ghAuthenticated: false,
        githubRemoteOk: true,
        githubRemoteLabel: 'org/repo',
        macosHost: false,
        xcodeInstalled: false,
        dockerAvailable: false,
      );
      expect(report.minimalReady, isTrue);
      expect(report.publishReady, isFalse);
    });
  });

  group('actArtifactName', () {
    test('returns a valid GitHub release artifact for this platform', () {
      if (!Platform.isMacOS && !Platform.isLinux) {
        expect(
          () => actArtifactName(),
          throwsA(isA<UnsupportedError>()),
        );
        return;
      }
      final name = actArtifactName();
      expect(name, startsWith('act_'));
      expect(name, endsWith('.tar.gz'));
      expect(actDownloadUrl(), contains('github.com/nektos/act/releases'));
    });
  });

  group('costEstimateWarnings', () {
    test('warns when iOS runs on PR in single-file mode', () {
      final spec = CiWorkflowSpec.fromPreset(CiWorkflowPreset.full).copyWith(
        pipelineMode: CiPipelineMode.single,
        onPullRequest: true,
      );
      final warnings = costEstimateWarnings(spec);
      expect(warnings, isNotEmpty);
    });
  });

  group('nativeTestStepIds', () {
    test('matches spec job toggles', () {
      final spec = CiWorkflowSpec.fromPreset(CiWorkflowPreset.prChecks);
      final ids = nativeTestStepIds(spec);
      expect(ids, contains('dart_analyze'));
      expect(ids, contains('architecture_audit'));
      expect(ids, isNot(contains('android_aab')));
    });
  });

  group('publishCiWorkflow', () {
    test('blocked when test not passed', () async {
      final state = CiTestJobState(status: CiTestJobStatus.failed);
      expect(
        () => publishCiWorkflow(
          projectRoot: Directory.current,
          testState: state,
          spec: CiWorkflowSpec.fromPreset(CiWorkflowPreset.release),
          writtenPaths: ['.github/workflows/flutter-release.yml'],
        ),
        throwsA(isA<CiPublishBlockedException>()),
      );
    });
  });

  group('isDockerAvailableForAct', () {
    test('returns bool without throwing when docker is absent', () async {
      final available = await isDockerAvailableForAct();
      expect(available, isA<bool>());
    });
  });
}
