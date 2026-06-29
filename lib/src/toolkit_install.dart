import 'dart:io';

import 'package:path/path.dart' as p;

import 'models.dart';

/// Current pub.dev / path package name.
const toolkitPackageName = 'flutter_project_setup_toolkit';

/// Previous package name (still recognized in existing consumer pubspecs).
const legacyToolkitPackageName = 'flutter_release_toolkit';

bool isToolkitPackageRoot(Directory dir) {
  final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
  if (!pubspec.existsSync()) {
    return false;
  }
  final content = pubspec.readAsStringSync();
  return _packageNamePattern(toolkitPackageName).hasMatch(content) ||
      _packageNamePattern(legacyToolkitPackageName).hasMatch(content);
}

RegExp _packageNamePattern(String name) =>
    RegExp('^name:\\s*$name\\s*\$', multiLine: true);

RegExp _dependencyPattern(String name) =>
    RegExp('^\\s*$name\\s*:', multiLine: true);

Directory? detectRunningToolkitRoot() {
  for (final envKey in [
    'FLUTTER_PROJECT_SETUP_TOOLKIT',
    'FLUTTER_RELEASE_TOOLKIT',
  ]) {
    final fromEnv = Platform.environment[envKey];
    if (fromEnv != null && fromEnv.isNotEmpty) {
      final dir = Directory(fromEnv);
      if (isToolkitPackageRoot(dir)) {
        return dir.absolute;
      }
    }
  }

  for (final start in <Directory>[
    File(Platform.script.toFilePath()).absolute.parent,
    Directory.current.absolute,
  ]) {
    var current = start;
    while (true) {
      if (isToolkitPackageRoot(current)) {
        return current;
      }
      final parent = current.parent;
      if (parent.path == current.path) {
        break;
      }
      current = parent;
    }
  }
  return null;
}

String posixRelativePath(Directory from, Directory to) {
  return p.posix.normalize(
    p.relative(to.absolute.path, from: from.absolute.path),
  );
}

bool hasFlutterReleaseToolkitDependency(Directory projectRoot) {
  final pubspec = File(p.join(projectRoot.path, 'pubspec.yaml'));
  if (!pubspec.existsSync()) {
    return false;
  }
  final content = pubspec.readAsStringSync();
  return _dependencyPattern(toolkitPackageName).hasMatch(content) ||
      _dependencyPattern(legacyToolkitPackageName).hasMatch(content);
}

String? resolveToolkitInstallPath(ToolkitInstallPlan plan) {
  if (plan.toolkitInstallPath != null && plan.toolkitInstallPath!.isNotEmpty) {
    return plan.toolkitInstallPath;
  }

  final detected = detectRunningToolkitRoot();
  if (detected != null) {
    return posixRelativePath(plan.projectRoot, detected);
  }

  final home = Platform.environment['HOME'];
  final candidates = <String>[
    if (home != null && home.isNotEmpty)
      p.join(home, 'Documents', 'flutter-project-setup-toolkit'),
    p.normalize(p.join(plan.projectRoot.path, '..', 'flutter-project-setup-toolkit')),
    if (plan.localToolkitPath != null)
      p.normalize(p.join(plan.projectRoot.path, plan.localToolkitPath!)),
  ];

  for (final candidate in candidates) {
    if (isToolkitPackageRoot(Directory(candidate))) {
      return posixRelativePath(plan.projectRoot, Directory(candidate));
    }
  }
  return null;
}

Directory? resolveToolkitDirectory(ToolkitInstallPlan plan) {
  final relative = resolveToolkitInstallPath(plan);
  if (relative == null) {
    return null;
  }
  final absolute = p.normalize(p.join(plan.projectRoot.path, relative));
  final dir = Directory(absolute);
  return dir.existsSync() ? dir.absolute : null;
}

class ToolkitInstallResult {
  ToolkitInstallResult({
    required this.applied,
    required this.skipped,
    this.detail,
    this.error,
  });

  final bool applied;
  final bool skipped;
  final String? detail;
  final String? error;
}

Future<ToolkitInstallResult> applyToolkitInstall(
  ToolkitInstallPlan plan, {
  bool dryRun = false,
}) async {
  switch (plan.mode) {
    case ToolkitInstallMode.localClone:
      return _verifyLocalClone(plan, dryRun: dryRun);
    case ToolkitInstallMode.globalCli:
      return _activateGlobalCli(plan, dryRun: dryRun);
    case ToolkitInstallMode.devDependency:
      return _addDevDependency(plan, dryRun: dryRun);
  }
}

Future<ToolkitInstallResult> _verifyLocalClone(
  ToolkitInstallPlan plan, {
  required bool dryRun,
}) async {
  final relative = plan.localToolkitPath ?? '../flutter-project-setup-toolkit';
  final absolute = p.normalize(p.join(plan.projectRoot.path, relative));
  if (!Directory(absolute).existsSync()) {
    return ToolkitInstallResult(
      applied: false,
      skipped: false,
      error: 'Local toolkit not found at $relative',
    );
  }
  if (!isToolkitPackageRoot(Directory(absolute))) {
    return ToolkitInstallResult(
      applied: false,
      skipped: false,
      error: 'Path is not a $toolkitPackageName checkout: $relative',
    );
  }
  if (dryRun) {
    return ToolkitInstallResult(
      applied: false,
      skipped: false,
      detail: 'Would verify local toolkit at $relative',
    );
  }
  return ToolkitInstallResult(
    applied: true,
    skipped: false,
    detail: 'Using local toolkit at $relative',
  );
}

Future<ToolkitInstallResult> _activateGlobalCli(
  ToolkitInstallPlan plan, {
  required bool dryRun,
}) async {
  final toolkitDir = resolveToolkitDirectory(plan);
  final args = toolkitDir != null
      ? ['pub', 'global', 'activate', '--source', 'path', toolkitDir.path]
      : [
          'pub',
          'global',
          'activate',
          toolkitPackageName,
        ];
  final label = toolkitDir != null
      ? 'dart ${args.join(' ')}'
      : 'dart pub global activate $toolkitPackageName';

  if (dryRun) {
    return ToolkitInstallResult(
      applied: false,
      skipped: false,
      detail: 'Would run: $label',
    );
  }

  final result = await Process.run('dart', args, runInShell: false);
  if (result.exitCode != 0) {
    final message = '${result.stderr}'.trim();
    return ToolkitInstallResult(
      applied: false,
      skipped: false,
      error: message.isEmpty ? 'dart pub global activate failed' : message,
    );
  }
  return ToolkitInstallResult(
    applied: true,
    skipped: false,
    detail: 'Activated global CLI (${toolkitDir != null ? 'path' : 'pub.dev'})',
  );
}

Future<ToolkitInstallResult> _addDevDependency(
  ToolkitInstallPlan plan, {
  required bool dryRun,
}) async {
  if (hasFlutterReleaseToolkitDependency(plan.projectRoot)) {
    return ToolkitInstallResult(
      applied: false,
      skipped: true,
      detail: 'pubspec.yaml already lists $toolkitPackageName',
    );
  }

  final path = resolveToolkitInstallPath(plan);
  final args = path != null
      ? ['pub', 'add', '--dev', toolkitPackageName, '--path', path]
      : [
          'pub',
          'add',
          '--dev',
          '$toolkitPackageName:${plan.pubspecVersionConstraint}',
        ];
  final label = 'dart ${args.join(' ')}';

  if (dryRun) {
    return ToolkitInstallResult(
      applied: false,
      skipped: false,
      detail: 'Would run: $label (in ${plan.projectRoot.path})',
    );
  }

  if (path != null) {
    final absolute = p.normalize(p.join(plan.projectRoot.path, path));
    if (!isToolkitPackageRoot(Directory(absolute))) {
      return ToolkitInstallResult(
        applied: false,
        skipped: false,
        error: 'Toolkit path not found or invalid: $path',
      );
    }
  }

  final result = await Process.run(
    'dart',
    args,
    workingDirectory: plan.projectRoot.path,
    runInShell: false,
  );
  if (result.exitCode != 0) {
    final message = '${result.stderr}'.trim();
    return ToolkitInstallResult(
      applied: false,
      skipped: false,
      error: message.isEmpty ? 'dart pub add failed' : message,
    );
  }

  return ToolkitInstallResult(
    applied: true,
    skipped: false,
    detail: path != null
        ? 'Added dev dependency (path: $path)'
        : 'Added dev dependency (pub.dev ${plan.pubspecVersionConstraint})',
  );
}
