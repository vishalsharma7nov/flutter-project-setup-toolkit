import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

import 'docs/project_docs_service.dart';
import 'docs/project_docs_spec.dart';
import 'toolkit_studio_cli.dart';

Future<int> runProjectDocs(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('project', abbr: 'p', help: 'Flutter project root', defaultsTo: '.')
    ..addFlag('preview', negatable: false, help: 'Preview generated docs')
    ..addFlag('write', negatable: false, help: 'Write documentation files')
    ..addOption(
      'overwrite',
      help: 'skipExisting | refreshGenerated | overwriteAll',
      defaultsTo: 'skipExisting',
    )
    ..addOption(
      'format',
      abbr: 'f',
      help: 'Output format for --preview: json or text',
      defaultsTo: 'text',
    )
    ..addFlag('browser', negatable: false, help: 'Open Docs Studio in browser')
    ..addFlag('no-browser', negatable: false, help: 'Do not open browser when launching studio');

  late ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    return 64;
  }

  if (args['preview'] as bool || args['write'] as bool) {
    return _runHeadless(args);
  }

  final forwarded = <String>[
    '--view',
    'docs',
    if (args['project'] != '.') ...['--project', args['project'] as String],
    if (args['no-browser'] as bool) '--no-browser',
    if (args['browser'] as bool) '--browser',
  ];
  return runToolkitStudio(forwarded);
}

Future<int> _runHeadless(ArgResults args) async {
  final projectRoot = Directory((args['project'] as String).trim()).absolute;
  final spec = ProjectDocsSpec(
    overwritePolicy: ProjectDocsOverwritePolicy.parse(
      args['overwrite'] as String?,
    ),
  );
  final service = ProjectDocsService();

  if (args['preview'] as bool) {
    final data = service.preview(projectRoot: projectRoot, spec: spec);
    final format = args['format'] as String;
    if (format == 'json') {
      stdout.writeln(const JsonEncoder.withIndent('  ').convert(data));
      return 0;
    }
    final files = data['files'] as Map<String, dynamic>? ?? {};
    for (final entry in files.entries) {
      stdout.writeln('=== ${entry.key} ===');
      stdout.writeln(entry.value);
      stdout.writeln();
    }
    final skipped = data['skip_reasons'] as Map<String, dynamic>? ?? {};
    if (skipped.isNotEmpty) {
      stderr.writeln('Would skip:');
      for (final entry in skipped.entries) {
        stderr.writeln('  ${entry.key}: ${entry.value}');
      }
    }
    return 0;
  }

  final result = service.write(projectRoot: projectRoot, spec: spec);
  final written = result['written'] as List<dynamic>? ?? [];
  stdout.writeln('Written ${written.length} file(s):');
  for (final path in written) {
    stdout.writeln('  $path');
  }
  final skipped = result['skipped'] as Map<String, dynamic>? ?? {};
  if (skipped.isNotEmpty) {
    stderr.writeln('Skipped ${skipped.length} file(s):');
    for (final entry in skipped.entries) {
      stderr.writeln('  ${entry.key}: ${entry.value}');
    }
  }
  return 0;
}
