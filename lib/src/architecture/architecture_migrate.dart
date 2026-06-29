import 'dart:io';

import 'package:path/path.dart' as p;

import '../config.dart';
import 'architecture_config.dart';
import 'architecture_preset.dart';
import 'project_bootstrap.dart';

class ArchitectureMigrationPlan {
  ArchitectureMigrationPlan({
    required this.projectPath,
    required this.configuredPreset,
    required this.missingPaths,
    required this.dryRun,
  });

  final String projectPath;
  final ArchitecturePreset? configuredPreset;
  final List<String> missingPaths;
  final bool dryRun;

  Map<String, dynamic> toJson() => {
        'project_path': projectPath,
        'configured_preset': configuredPreset?.id,
        'missing_paths': missingPaths,
        'dry_run': dryRun,
        'path_count': missingPaths.length,
      };

  String toHumanReadable() {
    final buffer = StringBuffer()
      ..writeln('Architecture migration plan: $projectPath')
      ..writeln('Configured preset: ${configuredPreset?.id ?? '(none)'}');
    if (missingPaths.isEmpty) {
      buffer.writeln('No missing bootstrap folders.');
    } else {
      buffer.writeln('Missing paths (${missingPaths.length}):');
      for (final path in missingPaths) {
        buffer.writeln('  + $path');
      }
      if (dryRun) {
        buffer.writeln('Dry-run only — no files created.');
      }
    }
    return buffer.toString();
  }
}

ArchitectureMigrationPlan planArchitectureMigration(Directory projectRoot) {
  ArchitectureConfig arch;
  try {
    arch = loadConfig(projectRoot).architecture;
  } on Object {
    arch = ArchitectureConfig.defaults();
  }

  final expected = _expectedBootstrapPaths(
    projectRoot: projectRoot,
    architecture: arch,
  );
  final missing = expected.where((path) {
    final absolute = p.join(projectRoot.path, path);
    if (path.endsWith('/')) {
      return !Directory(absolute).existsSync();
    }
    return !File(absolute).existsSync() && !Directory(absolute).existsSync();
  }).toList()
    ..sort();

  return ArchitectureMigrationPlan(
    projectPath: projectRoot.path,
    configuredPreset: arch.preset,
    missingPaths: missing,
    dryRun: true,
  );
}

Future<ArchitectureMigrationPlan> applyArchitectureMigration(
  Directory projectRoot, {
  bool dryRun = true,
}) async {
  final plan = planArchitectureMigration(projectRoot);
  if (dryRun || plan.missingPaths.isEmpty) {
    return ArchitectureMigrationPlan(
      projectPath: plan.projectPath,
      configuredPreset: plan.configuredPreset,
      missingPaths: plan.missingPaths,
      dryRun: dryRun,
    );
  }

  ArchitectureConfig arch;
  try {
    arch = loadConfig(projectRoot).architecture;
  } on Object {
    arch = ArchitectureConfig.defaults();
  }

  final envNames = _environmentNames(projectRoot);
  await bootstrapProjectArchitecture(
    projectRoot: projectRoot,
    architecture: arch,
    environmentNames: envNames,
    dryRun: false,
  );

  return ArchitectureMigrationPlan(
    projectPath: projectRoot.path,
    configuredPreset: arch.preset,
    missingPaths: plan.missingPaths,
    dryRun: false,
  );
}

List<String> _expectedBootstrapPaths({
  required Directory projectRoot,
  required ArchitectureConfig architecture,
}) {
  final paths = <String>[];

  if (architecture.bootstrap.core) {
    paths.addAll([
      'lib/core/',
      'lib/core/errors/',
      'lib/core/utils/',
    ]);
    if (architecture.preset.effectivePreset != ArchitecturePreset.microFeature) {
      paths.addAll([
        'lib/core/network/',
        'lib/core/theme/',
      ]);
    }
  }

  if (architecture.bootstrap.appRouter &&
      architecture.preset != ArchitecturePreset.microFeature) {
    paths.add('lib/app/');
    if (architecture.routing != ProjectRouting.none) {
      paths.add('lib/app/router/');
      paths.add('lib/app/router/app_router.dart');
    }
  }

  if (architecture.bootstrap.shared) {
    paths.addAll([
      'lib/shared/',
      'lib/shared/widgets/',
    ]);
  }

  if (architecture.preset == ArchitecturePreset.microFeature &&
      architecture.bootstrap.melos) {
    paths.addAll([
      'melos.yaml',
      'apps/shell/lib/',
      'packages/',
    ]);
  }

  return paths;
}

List<String> _environmentNames(Directory projectRoot) {
  try {
    final config = loadConfig(projectRoot);
    if (config.environments.isNotEmpty) {
      return config.environments.keys.toList();
    }
  } on Object {
    // fall through
  }
  return const ['dev', 'prod'];
}
