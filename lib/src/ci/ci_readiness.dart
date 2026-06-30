import 'dart:io';

import 'package:path/path.dart' as p;

import 'ci_workflow_spec.dart';

/// Detect Flutter version from `.fvmrc` or `.fvm/fvm_config.json`.
String? detectProjectFlutterVersion(Directory projectRoot) {
  final fvmrc = File(p.join(projectRoot.path, '.fvmrc'));
  if (fvmrc.existsSync()) {
    final content = fvmrc.readAsStringSync().trim();
    if (content.isNotEmpty) return content;
  }
  final fvmConfig = File(p.join(projectRoot.path, '.fvm', 'fvm_config.json'));
  if (fvmConfig.existsSync()) {
    final raw = fvmConfig.readAsStringSync();
    final match = RegExp(r'"flutter"\s*:\s*"([^"]+)"').firstMatch(raw);
    if (match != null) return match.group(1);
  }
  return null;
}

bool detectMelosMonorepo(Directory projectRoot) {
  return File(p.join(projectRoot.path, 'melos.yaml')).existsSync();
}

bool detectPluginExample(Directory projectRoot) {
  return Directory(p.join(projectRoot.path, 'example')).existsSync() &&
      File(p.join(projectRoot.path, 'pubspec.yaml')).existsSync();
}

List<String> costEstimateWarnings(CiWorkflowSpec spec) {
  final warnings = <String>[];
  if (spec.iosIpa && spec.onPullRequest && spec.pipelineMode == CiPipelineMode.single) {
    warnings.add(
      'iOS job on every PR uses macOS runners (~10× cost). '
      'Use split CI + release or cost-conscious preset.',
    );
  }
  if (spec.androidAab && spec.iosIpa && spec.onPullRequest) {
    warnings.add(
      'Release builds on pull_request increase CI minutes. '
      'Consider split workflows so PRs stay ubuntu-only.',
    );
  }
  return warnings;
}

String suggestedActCommand({
  required CiWorkflowSpec spec,
  required bool split,
}) {
  final workflow = split
      ? '.github/workflows/flutter-ci.yml'
      : '.github/workflows/flutter-release.yml';
  final archFlag = spec.actCompatFlutterX64 ? ' --container-architecture linux/amd64' : '';
  return 'act push -W $workflow -j analyze$archFlag';
}

String ciBranchProtectionHint() {
  return 'In GitHub → Settings → Branches → Branch protection rules, '
      'require status checks: analyze and architecture_audit before merging to main.';
}
