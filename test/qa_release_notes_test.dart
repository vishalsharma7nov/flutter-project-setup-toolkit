import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/qa/codebase_snapshot.dart';
import 'package:flutter_project_setup_toolkit/src/qa/qa_release_notes.dart';
import 'package:flutter_project_setup_toolkit/src/qa/qa_release_notes_export.dart';
import 'package:test/test.dart';

Future<void> _runGit(Directory dir, List<String> args) async {
  final result = await Process.run('git', args, workingDirectory: dir.path);
  if (result.exitCode != 0) {
    throw StateError(
      'git ${args.join(' ')} failed: ${result.stderr}',
    );
  }
}

Future<Directory> _createTwoCommitRepo() async {
  final dir = Directory.systemTemp.createTempSync('rtk_qa_notes_');
  await _runGit(dir, ['init']);
  await _runGit(dir, ['config', 'user.email', 'qa@test.local']);
  await _runGit(dir, ['config', 'user.name', 'QA Test']);

  File('${dir.path}/pubspec.yaml').writeAsStringSync('''
name: demo_app
description: Demo shopping app
version: 1.0.0
environment:
  sdk: ">=3.5.0 <4.0.0"
dependencies:
  dio: ^5.0.0
''');
  Directory('${dir.path}/lib/features/auth/presentation/pages').createSync(
    recursive: true,
  );
  File('${dir.path}/lib/main.dart')
      .writeAsStringSync('void main() {}\n');
  File('${dir.path}/lib/features/auth/presentation/pages/login_page.dart')
      .writeAsStringSync('class LoginPage {}\n');
  await _runGit(dir, ['add', '.']);
  await _runGit(dir, ['commit', '-m', 'feat: add home']);

  File('${dir.path}/lib/main.dart')
      .writeAsStringSync('void main() { print("ok"); }\n');
  await _runGit(dir, ['add', 'lib/main.dart']);
  await _runGit(dir, ['commit', '-m', 'fix: button tap PROJ-42']);

  return dir;
}

Directory _createNoGitProject() {
  final dir = Directory.systemTemp.createTempSync('rtk_qa_nogit_');
  File('${dir.path}/pubspec.yaml').writeAsStringSync('''
name: brownfield_app
description: Legacy field app for inventory
version: 1.0.0
environment:
  sdk: ">=3.5.0 <4.0.0"
dependencies:
  flutter_bloc: ^8.0.0
''');
  Directory('${dir.path}/lib/features/inventory/presentation/pages')
      .createSync(recursive: true);
  File('${dir.path}/lib/main.dart').writeAsStringSync('''
import 'package:flutter/material.dart';
void main() => runApp(MaterialApp(home: Scaffold()));
''');
  File('${dir.path}/lib/features/inventory/presentation/pages/stock_page.dart')
      .writeAsStringSync('class StockPage {}\n');
  File('${dir.path}/README.md').writeAsStringSync(
    '# Inventory\nTrack warehouse stock levels.',
  );
  return dir;
}

void main() {
  group('generateQaReleaseNotes', () {
    late Directory repo;

    setUp(() async {
      repo = await _createTwoCommitRepo();
    });

    tearDown(() {
      repo.deleteSync(recursive: true);
    });

    test('produces markdown with compare shas and checklist', () async {
      final result = await generateQaReleaseNotes(projectRoot: repo);
      final md = exportQaMarkdown(result);

      expect(result.source, QaSourceMode.git);
      expect(result.compare.shortBase, isNotEmpty);
      expect(result.compare.shortHead, isNotEmpty);
      expect(md, contains('fix: button tap'));
      expect(md, contains('lib/main.dart'));
      expect(result.checklist, isNotEmpty);
      expect(result.estimatedMinutes, greaterThanOrEqualTo(5));
      expect(result.ticketIds, contains('PROJ-42'));
    });

    test('exports csv, json, html, and xlsx', () async {
      final result = await generateQaReleaseNotes(projectRoot: repo);
      expect(exportQaCsv(result), contains('Checklist item'));
      expect(exportQaJson(result), contains('"project_name"'));
      expect(exportQaHtml(result), contains('<h1>'));
      expect(exportQaXlsx(result), isNotEmpty);
      expect(exportTestRailCsv(result), contains('Title'));
      expect(exportTuskrCsv(result), contains('Name'));
      expect(exportQaEml(result), contains('Subject: QA handoff'));
    });

    test('audience modes change markdown length', () async {
      final qa = await generateQaReleaseNotes(
        projectRoot: repo,
        audience: QaAudience.qa,
      );
      final exec = await generateQaReleaseNotes(
        projectRoot: repo,
        audience: QaAudience.executive,
      );
      expect(exportQaMarkdown(qa).length, greaterThan(exportQaMarkdown(exec).length));
    });

    test('single-commit repo falls back to codebase scan', () async {
      final single = Directory.systemTemp.createTempSync('rtk_qa_single_');
      File('${single.path}/pubspec.yaml').writeAsStringSync('''
name: solo
description: Solo app
environment:
  sdk: ">=3.5.0 <4.0.0"
''');
      Directory('${single.path}/lib').createSync();
      File('${single.path}/lib/main.dart').writeAsStringSync('void main() {}\n');
      await _runGit(single, ['init']);
      await _runGit(single, ['config', 'user.email', 'qa@test.local']);
      await _runGit(single, ['config', 'user.name', 'QA Test']);
      await _runGit(single, ['add', '.']);
      await _runGit(single, ['commit', '-m', 'init']);

      final result = await generateQaReleaseNotes(projectRoot: single);
      expect(result.source, QaSourceMode.codebase);
      expect(result.summary, contains('Solo app'));
      expect(result.codeUnderstanding, isNotNull);
      expect(result.checklist, isNotEmpty);

      single.deleteSync(recursive: true);
    });
  });

  group('codebase snapshot', () {
    test('infers modules screens and purpose without git', () async {
      final dir = _createNoGitProject();
      addTearDown(() => dir.deleteSync(recursive: true));

      final snapshot = analyzeCodebase(dir);
      expect(snapshot.projectName, 'brownfield_app');
      expect(snapshot.roughPurpose.toLowerCase(), contains('inventory'));
      expect(snapshot.featureModules, contains('inventory'));
      expect(snapshot.screens, contains('Stock'));
      expect(snapshot.keyDependencies, contains('flutter_bloc'));

      final result = await generateQaReleaseNotes(
        projectRoot: dir,
        sourceMode: QaSourceMode.codebase,
      );
      expect(result.source, QaSourceMode.codebase);
    });

    test('no-git project generates QA handoff via auto mode', () async {
      final dir = _createNoGitProject();
      addTearDown(() => dir.deleteSync(recursive: true));

      final result = await generateQaReleaseNotes(projectRoot: dir);
      expect(result.source, QaSourceMode.codebase);
      final md = exportQaMarkdown(result);
      expect(md, contains('Code understanding'));
      expect(md, contains('inventory'));
    });
  });
}
