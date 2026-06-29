import 'dart:io';

import 'package:path/path.dart' as p;

import '../config.dart';
import '../env/env_source.dart';
import '../flutter_tools.dart';

/// Clone root vs directory used for `flutter build` / install.
class QuickTestTarget {
  const QuickTestTarget({
    required this.repoRoot,
    required this.buildRoot,
    required this.isPlugin,
  });

  final Directory repoRoot;
  final Directory buildRoot;
  final bool isPlugin;

  Map<String, dynamic> toJson() => {
        'repo_root': repoRoot.path,
        'build_dir': buildRoot.path,
        'is_plugin': isPlugin,
        'uses_example_app': isPlugin && buildRoot.path != repoRoot.path,
      };
}

/// True when [pubspec.yaml] declares a Flutter plugin (`flutter:` → `plugin:`).
bool isFlutterPluginProject(Directory projectRoot) {
  validateFlutterProject(projectRoot);
  final content =
      File(p.join(projectRoot.path, 'pubspec.yaml')).readAsStringSync();
  if (!RegExp(r'^\s*flutter\s*:', multiLine: true).hasMatch(content)) {
    return false;
  }
  return RegExp(r'^\s*plugin\s*:', multiLine: true).hasMatch(content);
}

Directory? findPluginExampleApp(Directory repoRoot) {
  final example = Directory(p.join(repoRoot.path, 'example'));
  final pubspec = File(p.join(example.path, 'pubspec.yaml'));
  if (!pubspec.existsSync()) {
    return null;
  }
  if (!isFlutterSdkProject(example)) {
    return null;
  }
  return example;
}

QuickTestTarget resolveQuickTestTarget(Directory repoRoot) {
  if (isFlutterPluginProject(repoRoot)) {
    final example = findPluginExampleApp(repoRoot);
    if (example == null) {
      throw StateError(
        'Flutter plugin detected but no runnable example/ app found. '
        'Add an example app or set Git subdirectory to example/.',
      );
    }
    return QuickTestTarget(
      repoRoot: repoRoot,
      buildRoot: example,
      isPlugin: true,
    );
  }
  if (!isFlutterSdkProject(repoRoot)) {
    throw StateError('This repo is not a Flutter app or plugin');
  }
  return QuickTestTarget(
    repoRoot: repoRoot,
    buildRoot: repoRoot,
    isPlugin: false,
  );
}

/// Env file from the build app or plugin repo (example first, then plugin root).
ResolvedBuildEnv? resolveQuickTestEnvOptional({
  required QuickTestTarget target,
  required String envName,
  EnvSourceRequest? envSource,
}) {
  final roots = target.buildRoot.path == target.repoRoot.path
      ? [target.buildRoot]
      : [target.buildRoot, target.repoRoot];

  EnvSourceRequest? overlay = envSource;
  for (final root in roots) {
    final resolved = resolveBuildEnvOptional(
      projectRoot: root,
      envName: envName,
      envSource: overlay,
    );
    if (resolved != null) {
      return resolved;
    }
    overlay = null;
  }
  return null;
}

Future<void> ensureQuickTestBuildReady(QuickTestTarget target) async {
  if (target.buildRoot.path == target.repoRoot.path) {
    return;
  }
  final flutter = detectFlutter();
  final result = await Process.run(
    flutter.executable,
    flutter.buildArgs(['pub', 'get']),
    workingDirectory: target.buildRoot.path,
  );
  if (result.exitCode != 0) {
    throw StateError(
      'flutter pub get failed for example app: ${result.stderr}'.trim(),
    );
  }
}
