import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter_project_setup_toolkit/src/architecture/architecture_audit.dart'
    as audit;
import 'package:flutter_project_setup_toolkit/src/architecture/architecture_migrate.dart'
    as migrate;
import 'package:flutter_project_setup_toolkit/src/config.dart';

const _usage = '''
Architecture audit — detect preset drift and import violations.

Usage:
  dart run flutter_project_setup_toolkit:architecture_audit [options] [project]

Options:
  -p, --project   Flutter project root (default: current directory)
      --json      Emit JSON report
      --migrate   Dry-run: list missing architecture folders only
  -h, --help      Show this help

Examples:
  dart run flutter_project_setup_toolkit:architecture_audit --project .
  dart run flutter_project_setup_toolkit:architecture_audit --json
  dart run flutter_project_setup_toolkit:architecture_audit --migrate
''';

Future<int> runArchitectureAuditCli(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('project', abbr: 'p', help: 'Flutter project root')
    ..addFlag('json', negatable: false, help: 'Emit JSON report')
    ..addFlag(
      'migrate',
      negatable: false,
      help: 'Dry-run migration: missing folders only',
    );

  late ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    stderr.writeln(_usage);
    return 64;
  }

  if (args.rest.length > 1) {
    stderr.writeln('Unexpected arguments: ${args.rest.skip(1).join(' ')}');
    stderr.writeln(_usage);
    return 64;
  }

  final projectArg =
      args['project'] as String? ??
      (args.rest.isNotEmpty ? args.rest.first : null);
  final projectRoot = projectArg == null
      ? Directory.current
      : Directory(projectArg);

  try {
    validateFlutterProject(projectRoot);
  } on Object catch (e) {
    stderr.writeln('$e');
    return 64;
  }

  if (args['migrate'] as bool) {
    final plan = migrate.planArchitectureMigration(projectRoot);
    if (args['json'] as bool) {
      stdout.writeln(const JsonEncoder.withIndent('  ').convert(plan.toJson()));
    } else {
      stdout.writeln(plan.toHumanReadable());
    }
    return plan.missingPaths.isEmpty ? 0 : 1;
  }

  final report = audit.runArchitectureAudit(projectRoot);
  if (args['json'] as bool) {
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(report.toJson()));
  } else {
    stdout.writeln(report.toHumanReadable());
  }

  final hasErrors = report.issues.any((issue) => issue.severity == 'error');
  return hasErrors ? 1 : 0;
}
