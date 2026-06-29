import 'dart:io';

import 'package:args/args.dart';

import 'config.dart';
import 'feature_scaffold.dart';
import 'interactive.dart';
import 'models.dart';
import 'state_management.dart';
import 'architecture/architecture_config.dart';
import 'architecture/architecture_preset.dart';
import 'api/api_config.dart';
import 'api/api_protocol.dart';

import 'toolkit_studio_cli.dart';

Future<int> runMakeFeature(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('project', abbr: 'p', help: 'Flutter project root')
    ..addOption('feature', abbr: 'f', help: 'Feature name (folder name)')
    ..addOption('base-path', help: 'Base directory for features', defaultsTo: 'lib/features')
    ..addOption(
      'state-management',
      help: 'bloc | riverpod | provider | getx | none',
    )
    ..addOption(
      'architecture-preset',
      help: 'feature_first_clean | micro_feature | custom | … (all presets)',
    )
    ..addOption('api-protocol', help: 'rest | grpc | graphql | local_only')
    ..addFlag('dry-run', help: 'Print planned scaffold only', negatable: false)
    ..addFlag('yes', abbr: 'y', help: 'Skip interactive prompts', negatable: false)
    ..addFlag('gui', help: 'Open Flutter Project Setup Toolkit (feature view)', negatable: false);

  late ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    return 64;
  }

  final projectRoot = resolveProjectRoot(args['project'] as String?);
  if (args['gui'] as bool) {
    return runToolkitStudio([
      '--view',
      'feature',
      '--project',
      projectRoot.path,
    ]);
  }
  final dryRun = args['dry-run'] as bool;
  final assumeYes = args['yes'] as bool;
  var featureName = (args['feature'] as String?)?.trim();
  if ((featureName == null || featureName.isEmpty) && args.rest.isNotEmpty) {
    featureName = args.rest.first.trim();
  }
  final basePath = (args['base-path'] as String?)?.trim() ?? 'lib/features';
  var resolvedBasePath = basePath;

  var stateManagement = StateManagement.parse(args['state-management'] as String?);
  stateManagement ??= resolveStateManagementFromConfig(projectRoot);

  final config = loadConfig(projectRoot);
  var architecture = config.architecture;
  final archOverride = ArchitecturePreset.parse(
    args['architecture-preset'] as String?,
  );
  if (archOverride != null) {
    architecture = architecture.copyWith(
      preset: archOverride,
      featureBasePath: archOverride.defaultFeatureBasePath,
    );
  }
  var api = config.api;
  final apiOverride = ApiProtocol.parse(args['api-protocol'] as String?);
  if (apiOverride != null) {
    api = ApiConfig(protocol: apiOverride);
  }
  if (archOverride != null && basePath == 'lib/features') {
    resolvedBasePath = architecture.featureBasePath;
  }

  if (featureName == null || featureName.isEmpty) {
    if (assumeYes || !isInteractiveTerminal()) {
      stderr.writeln(
        'Feature name is required. Pass --feature <name>, a positional argument, '
        'or run interactively in a terminal.',
      );
      return 64;
    }
    print('');
    print('=== make_feature ===');
    print('Project: ${projectRoot.path}');
    print('');
    featureName = promptLine(
      'What feature do you want to work on?',
      defaultValue: '',
    );
    while (featureName == null || featureName.isEmpty) {
      featureName = promptLine('Feature name is required');
    }
    if (!promptYesNo('Use base path lib/features/?', defaultYes: true)) {
      final customBase = promptLine('Base path', defaultValue: resolvedBasePath);
      if (customBase.isNotEmpty) {
        resolvedBasePath = customBase;
      }
    }
  }

  if (stateManagement == null) {
    if (assumeYes || !isInteractiveTerminal()) {
      stateManagement = StateManagement.none;
    } else {
      stateManagement = promptStateManagement();
    }
  }

  final resolvedFeatureName = featureName;
  try {
    if (!dryRun && stateManagement != StateManagement.none) {
      final packageResult = await applyStateManagementPackages(
        projectRoot,
        stateManagement,
      );
      if (packageResult.applied && packageResult.detail != null) {
        print(packageResult.detail);
      } else if (packageResult.error != null) {
        stderr.writeln(packageResult.error);
        return 1;
      }
    }

    final result = await scaffoldFeature(
      projectRoot: projectRoot,
      featureName: resolvedFeatureName,
      basePath: resolvedBasePath,
      stateManagement: stateManagement,
      architecture: architecture,
      api: api,
      dryRun: dryRun,
    );
    printFeatureScaffoldSummary(result);
    if (!dryRun) {
      print('');
      print('Next: implement the feature, then commit with a conventional message:');
      print('  git commit -m "feat: describe ${result.featureName}"');
    }
    return 0;
  } on ArgumentError catch (e) {
    stderr.writeln(e.message);
    return 64;
  } on StateError catch (e) {
    stderr.writeln(e.message);
    return 1;
  }
}
