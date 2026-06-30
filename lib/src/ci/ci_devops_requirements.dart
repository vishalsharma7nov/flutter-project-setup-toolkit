import 'dart:io';

import 'package:path/path.dart' as p;

import 'ci_act_installer.dart';
import 'ci_features.dart';
import 'ci_workflow_spec.dart';

/// DevOps tooling tier for CI Studio preflight.
enum DevOpsRequirementTier {
  /// Must have to generate workflows and run native smoke tests.
  required,

  /// Must have to publish workflows via pull request.
  publish,

  /// Helpful when specific jobs are enabled; warns if missing.
  recommended,

  /// Nice to have — not required for core DevOps workflow.
  optional,
}

class DevOpsRequirement {
  DevOpsRequirement({
    required this.id,
    required this.tier,
    required this.ok,
    required this.label,
    required this.message,
    this.setupHint,
  });

  final String id;
  final DevOpsRequirementTier tier;
  final bool ok;
  final String label;
  final String message;
  final String? setupHint;

  Map<String, dynamic> toJson() => {
        'id': id,
        'tier': tier.name,
        'ok': ok,
        'label': label,
        'message': message,
        if (setupHint != null) 'setup_hint': setupHint,
      };
}

/// Minimal and optional DevOps requirements for Flutter CI/CD in this project.
DevOpsSetupReport evaluateDevOpsSetup({
  required Directory projectRoot,
  required CiWorkflowSpec spec,
  required bool hasToolkitConfig,
  required bool dartInstalled,
  required bool flutterInstalled,
  required bool gitInstalled,
  required bool ghInstalled,
  required bool ghAuthenticated,
  required bool githubRemoteOk,
  String? githubRemoteLabel,
  required bool macosHost,
  required bool xcodeInstalled,
  required bool dockerAvailable,
}) {
  final requirements = <DevOpsRequirement>[
    DevOpsRequirement(
      id: 'dart',
      tier: DevOpsRequirementTier.required,
      ok: dartInstalled,
      label: 'Dart SDK',
      message: dartInstalled ? 'Dart SDK on PATH' : 'Dart SDK not found',
      setupHint: dartInstalled ? null : 'Install Dart: https://dart.dev/get-dart',
    ),
    DevOpsRequirement(
      id: 'git',
      tier: DevOpsRequirementTier.required,
      ok: gitInstalled,
      label: 'Git',
      message: gitInstalled ? 'Git repository' : 'Git not found',
      setupHint: gitInstalled ? null : 'Install Git: https://git-scm.com/downloads',
    ),
    DevOpsRequirement(
      id: 'flutter',
      tier: DevOpsRequirementTier.required,
      ok: flutterInstalled,
      label: 'Flutter SDK',
      message: flutterInstalled
          ? 'Flutter on PATH (native smoke test + builds)'
          : 'Flutter not found — native CI test will fail',
      setupHint: flutterInstalled
          ? null
          : 'Install Flutter: https://docs.flutter.dev/get-started/install',
    ),
    DevOpsRequirement(
      id: 'toolkit_config',
      tier: DevOpsRequirementTier.required,
      ok: hasToolkitConfig,
      label: 'Project config',
      message: hasToolkitConfig
          ? 'release-toolkit.config.json'
          : 'Missing release-toolkit.config.json',
      setupHint: hasToolkitConfig
          ? null
          : 'Run Setup Studio or dart run :setup_project',
    ),
    DevOpsRequirement(
      id: 'github_remote',
      tier: DevOpsRequirementTier.publish,
      ok: githubRemoteOk,
      label: 'GitHub origin',
      message: githubRemoteOk
          ? 'GitHub remote: $githubRemoteLabel'
          : 'origin must point to github.com for PR publish',
      setupHint: githubRemoteOk
          ? null
          : 'git remote add origin git@github.com:org/repo.git',
    ),
    DevOpsRequirement(
      id: 'gh_cli',
      tier: DevOpsRequirementTier.publish,
      ok: ghInstalled && ghAuthenticated,
      label: 'GitHub CLI',
      message: ghAuthenticated
          ? 'gh authenticated'
          : ghInstalled
              ? 'Run gh auth login'
              : 'gh CLI not installed',
      setupHint: ghAuthenticated
          ? null
          : ghInstalled
              ? 'gh auth login'
              : 'Install: https://cli.github.com/',
    ),
  ];

  if (spec.androidAab &&
      Directory(p.join(projectRoot.path, 'android')).existsSync()) {
    final keyProps = File(p.join(projectRoot.path, 'android/key.properties'));
    requirements.add(
      DevOpsRequirement(
        id: 'android_signing',
        tier: DevOpsRequirementTier.recommended,
        ok: keyProps.existsSync(),
        label: 'Android signing',
        message: keyProps.existsSync()
            ? 'android/key.properties present'
            : 'Signing file missing — configure before release AAB in CI',
        setupHint: keyProps.existsSync()
            ? null
            : 'Create android/key.properties and GitHub secrets for release builds',
      ),
    );
  }

  if (spec.iosIpa) {
    requirements.add(
      DevOpsRequirement(
        id: 'ios_host',
        tier: DevOpsRequirementTier.recommended,
        ok: macosHost && xcodeInstalled,
        label: 'iOS build host',
        message: macosHost && xcodeInstalled
            ? 'macOS + Xcode available'
            : 'iOS IPA job needs macOS with Xcode for local test',
        setupHint: macosHost && xcodeInstalled
            ? null
            : 'Use a Mac with Xcode, or rely on GitHub macos-latest runners only',
      ),
    );
  }

  if (ciActStudioEnabled) {
    requirements.add(
      DevOpsRequirement(
        id: 'docker',
        tier: DevOpsRequirementTier.optional,
        ok: dockerAvailable,
        label: 'Docker (optional)',
        message: dockerAvailable
            ? 'Docker running — act workflow test available'
            : 'Docker not running — skip act; use native smoke test',
        setupHint: dockerAvailable
            ? null
            : 'Optional: install Docker Desktop only if DevOps wants act testing. '
                'Native smoke test does not need Docker.',
      ),
    );
  }

  final requiredOk = requirements
      .where((r) => r.tier == DevOpsRequirementTier.required)
      .every((r) => r.ok);
  final publishOk = requirements
      .where((r) => r.tier == DevOpsRequirementTier.publish)
      .every((r) => r.ok);
  final recommendedOk = requirements
      .where((r) => r.tier == DevOpsRequirementTier.recommended)
      .every((r) => r.ok);

  return DevOpsSetupReport(
    requirements: requirements,
    minimalReady: requiredOk,
    publishReady: requiredOk && publishOk,
    recommendedReady: recommendedOk,
  );
}

class DevOpsSetupReport {
  DevOpsSetupReport({
    required this.requirements,
    required this.minimalReady,
    required this.publishReady,
    required this.recommendedReady,
  });

  final List<DevOpsRequirement> requirements;
  final bool minimalReady;
  final bool publishReady;
  final bool recommendedReady;

  List<DevOpsRequirement> forTier(DevOpsRequirementTier tier) =>
      requirements.where((r) => r.tier == tier).toList();

  Map<String, dynamic> toJson() => {
        'minimal_ready': minimalReady,
        'publish_ready': publishReady,
        'recommended_ready': recommendedReady,
        'requirements': requirements.map((r) => r.toJson()).toList(),
        'summary': {
          'required': forTier(DevOpsRequirementTier.required)
              .map((r) => r.toJson())
              .toList(),
          'publish': forTier(DevOpsRequirementTier.publish)
              .map((r) => r.toJson())
              .toList(),
          'recommended': forTier(DevOpsRequirementTier.recommended)
              .map((r) => r.toJson())
              .toList(),
          'optional': forTier(DevOpsRequirementTier.optional)
              .map((r) => r.toJson())
              .toList(),
        },
        'minimal_setup_commands': minimalDevOpsSetupCommands(),
      };
}

/// Copy-paste bootstrap for a new DevOps engineer on a Flutter project.
List<Map<String, String>> minimalDevOpsSetupCommands() {
  return [
    {
      'title': 'Clone and open project',
      'command': 'git clone git@github.com:ORG/REPO.git && cd REPO',
    },
    {
      'title': 'Verify Dart + Flutter',
      'command': 'dart --version && flutter --version && flutter doctor',
    },
    {
      'title': 'Open CI Studio',
      'command': 'dart run :toolkit_studio --view ci --project .',
    },
    {
      'title': 'Authenticate GitHub CLI (for publish)',
      'command': 'gh auth login',
    },
    {
      'title': 'Native smoke test (no Docker)',
      'command': 'dart run :ci_studio --project . --write --test',
    },
  ];
}

/// Quick async probe used by detect endpoints.
Future<bool> isDartOnPath() async {
  final result = await Process.run('which', ['dart']);
  return result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty;
}

Future<DevOpsSetupReport> detectDevOpsSetup({
  required Directory projectRoot,
  required CiWorkflowSpec spec,
  required bool hasToolkitConfig,
  required bool flutterInstalled,
  required Map<String, dynamic> tooling,
  required Map<String, dynamic>? githubRemote,
}) async {
  final git = tooling['git'] as Map<String, dynamic>?;
  final gh = tooling['gh'] as Map<String, dynamic>?;
  final dockerOk =
      ciActStudioEnabled ? await isDockerAvailableForAct() : false;
  final dartOk = await isDartOnPath();
  final macos = Platform.isMacOS;
  var xcodeOk = false;
  if (macos) {
    final xcode = await Process.run('xcodebuild', ['-version']);
    xcodeOk = xcode.exitCode == 0;
  }

  final remoteOk = githubRemote?['is_github'] == true;
  final remoteLabel = remoteOk
      ? '${githubRemote!['owner']}/${githubRemote['repo']}'
      : null;

  return evaluateDevOpsSetup(
    projectRoot: projectRoot,
    spec: spec,
    hasToolkitConfig: hasToolkitConfig,
    dartInstalled: dartOk,
    flutterInstalled: flutterInstalled,
    gitInstalled: git?['installed'] == true,
    ghInstalled: gh?['installed'] == true,
    ghAuthenticated: gh?['authenticated'] == true,
    githubRemoteOk: remoteOk,
    githubRemoteLabel: remoteLabel,
    macosHost: macos,
    xcodeInstalled: xcodeOk,
    dockerAvailable: dockerOk,
  );
}
