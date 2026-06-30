import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'codebase_snapshot.dart';

/// CLI to print a rough understanding of what a Flutter project does.
Future<int> runCodebaseUnderstand(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('project', abbr: 'p', help: 'Flutter project root')
    ..addOption(
      'format',
      abbr: 'f',
      defaultsTo: 'text',
      help: 'Output: text or json',
    )
    ..addFlag('help', abbr: 'h', negatable: false);

  late final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    stderr.writeln(parser.usage);
    return 64;
  }

  if (args['help'] == true) {
    stdout.writeln(
      'Scan a Flutter project and infer rough purpose, modules, and QA focus.',
    );
    stdout.writeln('');
    stdout.writeln(parser.usage);
    return 0;
  }

  final projectPath = args['project'] as String?;
  final root = projectPath == null || projectPath.isEmpty
      ? Directory.current
      : Directory(p.normalize(projectPath));

  final pubspec = File(p.join(root.path, 'pubspec.yaml'));
  if (!pubspec.existsSync()) {
    stderr.writeln('Not a Flutter project: pubspec.yaml missing');
    return 1;
  }

  final snapshot = analyzeCodebase(root);
  final format = args['format'] as String;

  if (format == 'json') {
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(snapshot.toJson()));
    return 0;
  }

  stdout.writeln('Project: ${snapshot.projectName}');
  stdout.writeln('Purpose: ${snapshot.roughPurpose}');
  stdout.writeln('');
  stdout.writeln('Understanding:');
  for (final note in snapshot.understandingNotes) {
    stdout.writeln('  • $note');
  }
  if (snapshot.featureModules.isNotEmpty) {
    stdout.writeln('');
    stdout.writeln('Modules: ${snapshot.featureModules.join(', ')}');
  }
  if (snapshot.screens.isNotEmpty) {
    stdout.writeln('Screens: ${snapshot.screens.join(', ')}');
  }
  if (snapshot.routes.isNotEmpty) {
    stdout.writeln('Routes: ${snapshot.routes.take(10).join(', ')}');
  }
  stdout.writeln('');
  stdout.writeln(
    'Files: ${snapshot.dartFiles.length} Dart, ${snapshot.testFiles.length} test',
  );
  stdout.writeln('Platforms: ${snapshot.platforms.join(', ')}');
  return 0;
}
