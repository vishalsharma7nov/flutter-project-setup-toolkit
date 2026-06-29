import 'dart:io';

import 'package:args/args.dart';

import 'config.dart';
import 'interactive.dart';
import 'models.dart';
import 'toolkit_studio_cli.dart';
import 'setup_wizard.dart';

Future<int> runSetupProject(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('project', abbr: 'p', help: 'Flutter project root')
    ..addFlag('yes', abbr: 'y', help: 'Non-interactive defaults', negatable: false)
    ..addOption('preset', help: 'dev-prod | dev-staging-prod')
    ..addOption('env-dir', help: 'Env directory style: .env | .secrets')
    ..addOption('default-env', help: 'Default working environment name')
    ..addOption('toolkit-path', help: 'Path to flutter-project-setup-toolkit for dev dependency (relative to project)')
    ..addOption('make-feature', help: 'Scaffold this feature after setup (non-interactive)')
    ..addOption('feature-base-path', help: 'Base path for --make-feature', defaultsTo: 'lib/features')
    ..addOption('state-management', help: 'bloc | riverpod | provider | getx | none')
    ..addOption(
      'architecture-preset',
      help: 'feature_first_clean | layer_first_clean | compass_mvvm | simple',
    )
    ..addOption(
      'api-protocol',
      help: 'rest | grpc | graphql | local_only | external_sdk',
    )
    ..addFlag('force', help: 'Overwrite existing config/scripts', negatable: false)
    ..addFlag('dry-run', help: 'Print planned changes only', negatable: false)
    ..addFlag('gui', help: 'Open Flutter Project Setup Toolkit (setup view)', negatable: false)
    ..addOption('port', help: 'Setup Studio port (with --gui)', defaultsTo: '8766')
    ..addFlag('no-browser', help: 'Do not open browser (with --gui)', negatable: false);

  late ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    return 64;
  }

  if (args.rest.isNotEmpty) {
    stderr.writeln('Unexpected arguments: ${args.rest.join(' ')}');
    return 64;
  }

  final projectRoot = resolveProjectRoot(args['project'] as String?);

  if (args['gui'] as bool) {
    return runToolkitStudio([
      '--view',
      'setup',
      '--project',
      projectRoot.path,
      '--port',
      args['port'] as String,
      if (args['no-browser'] as bool) '--no-browser',
    ]);
  }

  final assumeYes = args['yes'] as bool;
  final dryRun = args['dry-run'] as bool;
  final force = args['force'] as bool;

  if (!assumeYes && !isInteractiveTerminal()) {
    stderr.writeln(
      'Interactive setup requires a terminal. Re-run with --yes for defaults, '
      'or pass --preset, --env-dir, and --default-env.',
    );
    return 1;
  }

  try {
    SetupPlan plan;
    if (assumeYes || args['preset'] != null) {
      plan = buildSetupPlanNonInteractive(
        projectRoot: projectRoot,
        preset: args['preset'] as String? ?? 'dev-prod',
        envDir: args['env-dir'] as String? ?? '.env',
        defaultEnvironment: args['default-env'] as String? ?? 'dev',
        toolkitPath: args['toolkit-path'] as String?,
        makeFeature: args['make-feature'] as String?,
        featureBasePath: args['feature-base-path'] as String? ?? 'lib/features',
        stateManagement: StateManagement.parse(
              args['state-management'] as String?,
            ) ??
            StateManagement.none,
        architecturePreset: args['architecture-preset'] as String?,
        apiProtocol: args['api-protocol'] as String?,
      );
    } else {
      plan = await collectSetupPlanInteractive(
        projectRoot: projectRoot,
        assumeYes: false,
      );
    }

    if (!dryRun && !assumeYes && isInteractiveTerminal()) {
      final reviewed = await reviewSetupPlanInteractive(plan);
      if (reviewed == null) {
        print('Setup cancelled.');
        return 0;
      }
      plan = reviewed;
    }

    var result = await applySetupPlan(plan, force: force, dryRun: dryRun);

    if (!dryRun && isInteractiveTerminal() && setupHasRetryableFailures(result)) {
      final retried = await retryFailedSetupInteractive(plan, result);
      plan = retried.plan;
      result = retried.result;
    }

    printSetupSummary(plan, result);
    if (result.toolkitInstall?.error != null) {
      return 1;
    }
    return 0;
  } on StateError catch (e) {
    stderr.writeln(e.message);
    return 1;
  } on ArgumentError catch (e) {
    stderr.writeln(e.message);
    return 64;
  }
}
