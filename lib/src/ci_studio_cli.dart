import 'dart:io';

import 'package:args/args.dart';

import 'ci/ci_studio_service.dart';
import 'ci/ci_publish_service.dart';
import 'ci/ci_workflow_spec.dart';
import 'config.dart';
import 'toolkit_studio_cli.dart';

Future<int> runCiStudio(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('project', abbr: 'p', help: 'Flutter project root', defaultsTo: '.')
    ..addOption('preset', help: 'Workflow preset: prChecks | release | full | costConsciousWeeklyShip')
    ..addFlag('write', negatable: false, help: 'Write workflow files locally')
    ..addFlag('test', negatable: false, help: 'Run native smoke test (exit 0/1)')
    ..addFlag('publish', negatable: false, help: 'Publish via gh pr (requires passing test)')
    ..addFlag('browser', negatable: false, help: 'Open CI Studio in browser')
    ..addFlag('no-browser', negatable: false, help: 'Do not open browser when launching studio');

  late ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    return 64;
  }

  if (args['write'] as bool || args['test'] as bool || args['publish'] as bool) {
    return _runHeadless(args);
  }

  final forwarded = <String>[
    '--view',
    'ci',
    if (args['project'] != '.') ...['--project', args['project'] as String],
    if (args['no-browser'] as bool) '--no-browser',
    if (args['browser'] as bool) '--browser',
  ];
  return runToolkitStudio(forwarded);
}

Future<int> _runHeadless(ArgResults args) async {
  final projectRoot = Directory((args['project'] as String).trim()).absolute;
  validateFlutterProject(projectRoot);

  final presetRaw = args['preset'] as String?;
  final preset = CiWorkflowPreset.values.firstWhere(
    (p) => p.name == presetRaw,
    orElse: () => CiWorkflowPreset.full,
  );
  final spec = CiWorkflowSpec.fromPreset(preset);
  final service = CiStudioService();

  if (args['write'] as bool) {
    service.write(projectRoot: projectRoot, spec: spec);
    stdout.writeln('Wrote CI workflow(s) to ${projectRoot.path}');
  }

  if (args['test'] as bool) {
    await service.runNativeTest(projectRoot: projectRoot, spec: spec);
    if (service.testState.passed) {
      stdout.writeln('Native smoke test passed');
      return 0;
    }
    stderr.writeln(service.testState.error ?? 'Native smoke test failed');
    return 1;
  }

  if (args['publish'] as bool) {
    if (!(args['test'] as bool) && !service.testState.passed) {
      stderr.writeln('Run --test first or pass tests in CI Studio before --publish');
      return 1;
    }
    try {
      if (!(args['write'] as bool)) {
        service.write(projectRoot: projectRoot, spec: spec);
      }
      if (!service.testState.passed) {
        await service.runNativeTest(projectRoot: projectRoot, spec: spec);
      }
      final result = await service.publish(projectRoot: projectRoot, spec: spec);
      stdout.writeln('Published: ${result.prUrl ?? result.branch}');
      return 0;
    } on CiPublishBlockedException catch (e) {
      stderr.writeln(e.message);
      return 1;
    }
  }

  return 0;
}
