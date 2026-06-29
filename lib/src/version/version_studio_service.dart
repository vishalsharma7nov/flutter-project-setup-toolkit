import 'dart:convert';
import 'dart:io';

import '../classify.dart';
import '../config.dart';
import '../git_runner.dart';
import '../models.dart';
import '../version_logic.dart';

/// Preview semver bump from the latest (or specified) commit.
Future<Map<String, dynamic>> versionClassifyPreview({
  required Directory projectRoot,
  String commit = 'HEAD',
  String? envName,
  String? envFilePath,
}) async {
  final config = loadConfig(projectRoot);
  final git = GitRunner(projectRoot);
  final loaded = await git.loadCommit(commit);
  final classification = classifyCommit(
    loaded.subject,
    loaded.body,
    loaded.changes,
    loaded.diff,
  );
  final shortSha = await git.shortSha(commit);

  final env = envName ?? config.defaultEnvironment ?? 'dev';
  final targets = resolveEnvTargets(
    config,
    env,
    envFilePath == null ? null : File(envFilePath),
  );

  final environments = <String, dynamic>{};
  for (final target in targets) {
    if (!target.value.existsSync()) {
      environments[target.key] = {
        'env_file': target.value.path,
        'error': 'Env file not found',
      };
      continue;
    }
    final bump = buildEnvVersionUpdates(
      classification.level,
      target.value,
      projectRoot,
      config,
    );
    environments[target.key] = {
      'env_file': target.value.path,
      'env_updates': bump.updates,
      if (bump.current.android != null)
        'android': {
          'current': bump.current.android!.pubspec,
          'suggested': bump.suggested.android?.pubspec ?? '',
        },
      if (bump.current.ios != null)
        'ios': {
          'current': bump.current.ios!.pubspec,
          'suggested': bump.suggested.ios?.pubspec ?? '',
        },
    };
  }

  return {
    'commit': shortSha,
    'subject': loaded.subject,
    'bump': classification.level.name,
    'reasons': classification.reasons,
    'environments': config.environments,
    'default_environment': config.defaultEnvironment,
    'selected_env': env,
    'preview': environments,
  };
}

/// Apply version bump to env file(s).
Future<Map<String, dynamic>> versionClassifyApply({
  required Directory projectRoot,
  String commit = 'HEAD',
  String? envName,
  String? envFilePath,
  bool dryRun = false,
}) async {
  final preview = await versionClassifyPreview(
    projectRoot: projectRoot,
    commit: commit,
    envName: envName,
    envFilePath: envFilePath,
  );
  final config = loadConfig(projectRoot);
  final level = BumpLevel.values.firstWhere(
    (b) => b.name == preview['bump'],
    orElse: () => BumpLevel.patch,
  );
  final env = envName ?? config.defaultEnvironment ?? 'dev';
  final targets = resolveEnvTargets(
    config,
    env,
    envFilePath == null ? null : File(envFilePath),
  );

  final applied = <String, dynamic>{};
  for (final target in targets) {
    if (!target.value.existsSync()) {
      throw StateError('Env file not found: ${target.value.path}');
    }
    final bump = buildEnvVersionUpdates(
      level,
      target.value,
      projectRoot,
      config,
    );
    final changes = applyVersionToEnvFile(
      target.value,
      bump.updates,
      config.versionKeyList,
      dryRun: dryRun,
    );
    applied[target.key] = {
      'env_file': target.value.path,
      'dry_run': dryRun,
      'changes': {
        for (final entry in changes.entries)
          entry.key: {'from': entry.value.from, 'to': entry.value.to},
      },
    };
  }

  return {
    ...preview,
    'applied': !dryRun,
    'results': applied,
  };
}

Map<String, dynamic> versionEnvironmentsForProject(Directory projectRoot) {
  final config = loadConfig(projectRoot);
  return {
    'environments': config.environments,
    'default_environment': config.defaultEnvironment,
  };
}

String encodeVersionJson(Map<String, dynamic> data) =>
    const JsonEncoder.withIndent('  ').convert(data);
