import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'qa_release_notes.dart';
import 'qa_release_notes_export.dart';

/// CLI for QA release notes — used locally and in CI artifact uploads.
Future<int> runQaReleaseNotes(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'project',
      abbr: 'p',
      help: 'Flutter project root (default: current directory)',
    )
    ..addOption(
      'base-mode',
      defaultsTo: 'head~1',
      help: 'Compare base: head~1, last_tag, or codebase',
    )
    ..addOption(
      'source',
      defaultsTo: 'auto',
      help: 'Source: auto (fallback to codebase), git, or codebase',
    )
    ..addOption(
      'format',
      abbr: 'f',
      defaultsTo: 'json',
      help:
          'Output format: json, md, csv, html, xlsx, testrail, tuskr, regression, eml',
    )
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Write output to file (required for xlsx)',
    )
    ..addOption(
      'audience',
      defaultsTo: 'qa',
      help: 'Audience template: qa, pm, executive',
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
    stdout.writeln('Generate QA release notes for HEAD~1..HEAD (or last tag..HEAD).');
    stdout.writeln('');
    stdout.writeln(parser.usage);
    return 0;
  }

  final projectPath = args['project'] as String?;
  final root = projectPath == null || projectPath.isEmpty
      ? Directory.current
      : Directory(p.normalize(projectPath));

  try {
    final baseMode = args['base-mode'] as String;
    final sourceMode = QaSourceMode.parse(
      baseMode == 'codebase' ? 'codebase' : (args['source'] as String?),
    );
    final base = baseMode == 'codebase'
        ? 'HEAD~1'
        : await resolveCompareBase(root, mode: baseMode);
    final result = await generateQaReleaseNotes(
      projectRoot: root,
      base: base,
      audience: QaAudience.parse(args['audience'] as String?),
      sourceMode: sourceMode,
    );

    final format = args['format'] as String;
    final outputPath = args['output'] as String?;
    final (contentType, bytes) = encodeQaDownload(result, format);

    if (outputPath != null) {
      await File(outputPath).writeAsBytes(bytes);
      stderr.writeln('Wrote $outputPath ($contentType)');
    } else if (format == 'json') {
      stdout.writeln(const JsonEncoder.withIndent('  ').convert(result.toJson()));
    } else if (format == 'xlsx') {
      stderr.writeln('xlsx requires --output <file>');
      return 64;
    } else {
      stdout.write(utf8.decode(bytes));
    }
    return 0;
  } on Object catch (e) {
    stderr.writeln('Error: $e');
    return 1;
  }
}
