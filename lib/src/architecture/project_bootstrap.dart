import 'dart:io';

import 'package:path/path.dart' as p;

import 'architecture_config.dart';
import 'architecture_preset.dart';
import 'core_modules_scaffold.dart';
import 'micro_feature_scaffold.dart';
import 'routing_scaffold.dart';

class ProjectBootstrapResult {
  ProjectBootstrapResult({
    required this.createdPaths,
    required this.dryRun,
  });

  final List<String> createdPaths;
  final bool dryRun;
}

Future<ProjectBootstrapResult> bootstrapProjectArchitecture({
  required Directory projectRoot,
  required ArchitectureConfig architecture,
  List<String> environmentNames = const ['dev', 'prod'],
  bool dryRun = false,
}) async {
  final created = <String>[];
  final dirs = <String>[];
  final files = <String, String>{};

  if (architecture.preset == ArchitecturePreset.microFeature &&
      architecture.bootstrap.melos) {
    final projectName = readProjectPackageName(projectRoot);
    files['melos.yaml'] = microFeatureMelosYaml(projectName);
    dirs.addAll([
      'apps/shell/lib',
      'packages',
    ]);
    files['apps/shell/pubspec.yaml'] = microFeatureShellPubspec();
    files['apps/shell/lib/main.dart'] = microFeatureShellMain();
  }

  if (architecture.bootstrap.core) {
    dirs.addAll([
      'lib/core',
      'lib/core/errors',
      'lib/core/utils',
    ]);
    if (architecture.preset.effectivePreset == ArchitecturePreset.compassMvvm) {
      dirs.addAll([
        'lib/ui/core',
        'lib/ui/core/themes',
        'lib/data/repositories',
        'lib/data/services',
        'lib/data/model',
        'lib/domain/models',
        'lib/routing',
      ]);
    } else if (architecture.preset == ArchitecturePreset.redux) {
      dirs.addAll([
        'lib/core/network',
        'lib/core/theme',
        'lib/store',
      ]);
    } else if (architecture.preset == ArchitecturePreset.riverpodFirst) {
      dirs.addAll([
        'lib/core/network',
        'lib/core/theme',
        'lib/core/di',
      ]);
    } else if (architecture.preset != ArchitecturePreset.microFeature) {
      dirs.addAll([
        'lib/core/network',
        'lib/core/theme',
      ]);
    }
  }

  if (architecture.coreModules.anyEnabled) {
    dirs.addAll(coreModuleScaffoldDirectories(architecture.coreModules));
    files.addAll(coreModuleScaffoldFiles(architecture.coreModules));
  }

  if (architecture.bootstrap.shared) {
    dirs.addAll([
      'lib/shared',
      'lib/shared/widgets',
    ]);
  }

  if (architecture.bootstrap.appRouter &&
      architecture.preset != ArchitecturePreset.microFeature) {
    dirs.addAll([
      'lib/app',
      if (architecture.routing != ProjectRouting.none) 'lib/app/router',
    ]);
    files.addAll(
      routingScaffoldFiles(
        routing: architecture.routing,
        environmentNames: environmentNames,
        flavorMains: architecture.bootstrap.flavorMains,
      ),
    );
  } else if (architecture.bootstrap.flavorMains) {
    files.addAll(
      routingScaffoldFiles(
        routing: ProjectRouting.none,
        environmentNames: environmentNames,
        flavorMains: true,
      ),
    );
  }

  for (final dir in dirs) {
    if (dryRun) {
      created.add('$dir/');
      continue;
    }
    Directory(p.join(projectRoot.path, dir)).createSync(recursive: true);
    created.add('$dir/');
  }

  for (final entry in files.entries) {
    if (dryRun) {
      created.add(entry.key);
      continue;
    }
    final file = File(p.join(projectRoot.path, entry.key));
    if (file.existsSync()) continue;
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(entry.value);
    created.add(entry.key);
  }

  return ProjectBootstrapResult(createdPaths: created, dryRun: dryRun);
}
