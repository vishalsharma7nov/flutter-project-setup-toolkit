import 'dart:io';

import 'package:path/path.dart' as p;

import '../config.dart';
import '../env/env_source.dart';
import '../flutter_tools.dart';
import 'ci_act_runner.dart';
import 'ci_diff.dart';
import 'ci_local_runner.dart';
import 'ci_publish_service.dart';
import 'ci_devops_requirements.dart';
import 'ci_features.dart';
import 'ci_readiness.dart';
import 'ci_secrets_checklist.dart';
import 'ci_test_models.dart';
import 'ci_tooling_detect.dart';
import 'ci_workflow_paths.dart';
import 'ci_workflow_spec.dart';
import 'ci_yaml_validate.dart';
import 'github_actions_template.dart';

class CiStudioService {
  CiStudioService({CiTestJobState? testState})
      : testState = testState ?? CiTestJobState() {
    localRunner = CiLocalRunner(jobState: this.testState);
    actRunner = CiActRunner(jobState: this.testState);
  }

  final CiTestJobState testState;
  late final CiLocalRunner localRunner;
  late final CiActRunner actRunner;

  bool testInProgress = false;
  List<String>? lastWrittenPaths;

  Future<Map<String, dynamic>> detect(Directory projectRoot) async {
    validateFlutterProject(projectRoot);
    final tooling = await detectCiTooling();
    final remote = await detectGitHubRemote(projectRoot);

    ToolkitConfig? config;
    var hasConfig = false;
    String? configError;
    try {
      config = loadConfig(projectRoot);
      hasConfig = true;
    } on Object catch (e) {
      configError = '$e';
    }

    final workflowsDir = Directory(p.join(projectRoot.path, '.github', 'workflows'));
    final existing = <String, String>{};
    if (workflowsDir.existsSync()) {
      for (final entity in workflowsDir.listSync()) {
        if (entity is File && entity.path.endsWith('.yml')) {
          existing[p.relative(entity.path, from: projectRoot.path)] =
              entity.readAsStringSync();
        }
      }
    }

    final defaultSpec = _defaultSpecFromConfig(projectRoot, config);
    final flutterInstalled = _flutterInstalled();

    final devopsSetup = await detectDevOpsSetup(
      projectRoot: projectRoot,
      spec: defaultSpec,
      hasToolkitConfig: hasConfig,
      flutterInstalled: flutterInstalled,
      tooling: tooling,
      githubRemote: remote,
    );

    // Legacy flat checks for existing clients.
    final checks = devopsSetup.requirements
        .where((r) => r.tier != DevOpsRequirementTier.optional)
        .map(
          (r) => {
            'id': r.id,
            'ok': r.ok,
            'message': r.message,
            if (r.setupHint != null) 'fix': r.setupHint,
          },
        )
        .toList();

    final flutterVersion = detectProjectFlutterVersion(projectRoot);
    final costWarnings = costEstimateWarnings(defaultSpec);
    final actCommand = ciActStudioEnabled
        ? suggestedActCommand(
            spec: defaultSpec,
            split: defaultSpec.pipelineMode == CiPipelineMode.split,
          )
        : null;

    return {
      'project_path': projectRoot.path,
      'has_config': hasConfig,
      if (configError != null) 'config_error': configError,
      'default_spec': defaultSpec.toJson(),
      'existing_workflows': existing.keys.toList(),
      'existing_workflow_contents': existing,
      'tooling': tooling,
      'github_remote': remote,
      'checks': checks,
      'devops_setup': devopsSetup.toJson(),
      'secrets_checklist': ciSecretsChecklist(
        spec: defaultSpec,
        envPaths: config?.environments,
      ).map((s) => s.toJson()).toList(),
      'environment_names': config?.environments.keys.toList() ?? ['dev', 'prod'],
      'default_environment': config?.defaultEnvironment ?? 'dev',
      'flutter_version': flutterVersion,
      'melos_monorepo': detectMelosMonorepo(projectRoot),
      'plugin_example': detectPluginExample(projectRoot),
      'cost_warnings': costWarnings,
      if (actCommand != null) 'act_command': actCommand,
      'features': {'act': ciActStudioEnabled},
    };
  }

  Map<String, dynamic> preview({
    required Directory projectRoot,
    required CiWorkflowSpec spec,
    ToolkitConfig? config,
  }) {
    final effectiveConfig = config ?? loadConfig(projectRoot);
    final files = generateWorkflowFiles(spec: spec, config: effectiveConfig);
    final diffs = <String, String>{};
    for (final entry in files.entries) {
      final existingFile = File(p.join(projectRoot.path, entry.key));
      if (existingFile.existsSync()) {
        diffs[entry.key] = unifiedDiff(
          oldText: existingFile.readAsStringSync(),
          newText: entry.value,
          oldLabel: entry.key,
          newLabel: '${entry.key} (generated)',
        );
      }
    }
    final validationErrors = <String, String?>{};
    for (final entry in files.entries) {
      validationErrors[entry.key] = validateWorkflowYaml(entry.value);
    }
    return {
      'files': files,
      'diffs': diffs,
      'validation_errors': validationErrors,
      'workflow_paths': files.keys.toList(),
      'secrets_checklist': ciSecretsChecklist(
        spec: spec,
        envPaths: effectiveConfig.environments,
      ).map((s) => s.toJson()).toList(),
      'cost_warnings': costEstimateWarnings(spec),
      'overwrite_warning': diffs.isNotEmpty
          ? 'Existing workflow files will be replaced. Review the diff before writing.'
          : null,
    };
  }

  Map<String, dynamic> write({
    required Directory projectRoot,
    required CiWorkflowSpec spec,
    ToolkitConfig? config,
    bool includeFastlane = true,
    bool includeCiSetupDoc = true,
  }) {
    final effectiveConfig = config ?? loadConfig(projectRoot);
    final files = generateWorkflowFiles(spec: spec, config: effectiveConfig);
    final written = <String>[];

    for (final entry in files.entries) {
      final error = validateWorkflowYaml(entry.value);
      if (error != null) {
        throw ArgumentError('Invalid YAML for ${entry.key}: $error');
      }
      final file = File(p.join(projectRoot.path, entry.key));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(entry.value);
      written.add(entry.key);
    }

    if (includeFastlane &&
        (spec.androidAab || spec.iosIpa || spec.firebaseAppDistribution)) {
      final fastlane = File(p.join(projectRoot.path, 'fastlane', 'Fastfile'));
      if (!fastlane.existsSync()) {
        fastlane.parent.createSync(recursive: true);
        fastlane.writeAsStringSync(
          generateFastlaneStub(firebase: spec.firebaseAppDistribution),
        );
        written.add('fastlane/Fastfile');
      }
    }

    final actExample = File(p.join(projectRoot.path, CiWorkflowPaths.actSecretsExample));
    if (!actExample.existsSync()) {
      actExample.writeAsStringSync(generateActSecretsExample());
      written.add(CiWorkflowPaths.actSecretsExample);
    }

    if (includeCiSetupDoc) {
      final secrets = ciSecretsChecklist(
        spec: spec,
        envPaths: effectiveConfig.environments,
      );
      final setupDoc = File(p.join(projectRoot.path, CiWorkflowPaths.ciSetupDoc));
      setupDoc.writeAsStringSync(
        generateCiSetupMarkdown(spec: spec, secrets: secrets),
      );
      written.add(CiWorkflowPaths.ciSetupDoc);
    }

    lastWrittenPaths = written;
    testState.status = CiTestJobStatus.idle;

    return {
      'written': written,
      'workflow_paths': files.keys.toList(),
    };
  }

  Future<void> runNativeTest({
    required Directory projectRoot,
    required CiWorkflowSpec spec,
    EnvSourceRequest? envOverlay,
  }) async {
    if (testInProgress) {
      throw StateError('A test is already running');
    }
    testInProgress = true;
    try {
      final config = loadConfig(projectRoot);
      await localRunner.run(
        projectRoot: projectRoot,
        spec: spec,
        config: config,
        envOverlay: envOverlay,
      );
    } finally {
      testInProgress = false;
    }
  }

  Future<void> runActTest({
    required Directory projectRoot,
    required CiWorkflowSpec spec,
    String job = 'analyze',
  }) async {
    if (testInProgress) {
      throw StateError('A test is already running');
    }
    testInProgress = true;
    try {
      final workflowPath = actRunner.suggestedWorkflowPath(
        split: spec.pipelineMode == CiPipelineMode.split,
      );
      await actRunner.run(
        projectRoot: projectRoot,
        workflowPath: workflowPath,
        job: job,
      );
    } finally {
      testInProgress = false;
    }
  }

  Future<CiPublishResult> publish({
    required Directory projectRoot,
    required CiWorkflowSpec spec,
  }) async {
    final paths = lastWrittenPaths ??
        CiWorkflowPaths.workflowFilesFor(
          split: spec.pipelineMode == CiPipelineMode.split,
          hasCiJobs: spec.hasCiJobs,
          hasReleaseJobs: spec.hasReleaseJobs,
        );
    final config = loadConfig(projectRoot);
    return publishCiWorkflow(
      projectRoot: projectRoot,
      testState: testState,
      spec: spec,
      writtenPaths: paths.where((p) => p.contains('workflows')).toList(),
      envPaths: config.environments,
    );
  }

  CiWorkflowSpec _defaultSpecFromConfig(Directory projectRoot, ToolkitConfig? config) {
    if (config == null) {
      return CiWorkflowSpec.fromPreset(CiWorkflowPreset.full);
    }
    return CiWorkflowSpec.fromPreset(CiWorkflowPreset.full).copyWith(
      defaultEnv: config.defaultEnvironment ?? 'dev',
      environmentNames: config.environments.keys.toList(),
      actCompatFlutterX64: Platform.isMacOS && _isAppleSilicon(),
      flutterVersion: detectProjectFlutterVersion(projectRoot),
    );
  }

  bool _flutterInstalled() {
    try {
      detectFlutter();
      return true;
    } on Object {
      return false;
    }
  }

  bool _isAppleSilicon() {
    final result = Process.runSync('uname', ['-m']);
    return result.stdout.toString().trim() == 'arm64';
  }
}
