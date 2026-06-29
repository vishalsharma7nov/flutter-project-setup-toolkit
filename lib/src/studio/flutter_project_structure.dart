import 'dart:io';

import 'package:path/path.dart' as p;

import '../config.dart';
import '../flutter_tools.dart';

/// Result of inspecting a folder for Flutter project layout.
class FlutterProjectAnalysis {
  FlutterProjectAnalysis({
    required this.projectPath,
    required this.projectName,
    required this.compatible,
    required this.canRepair,
    required this.issues,
    required this.missing,
  });

  final String projectPath;
  final String projectName;
  final bool compatible;
  final bool canRepair;
  final List<String> issues;
  final List<String> missing;

  Map<String, dynamic> toJson() => {
        'project_path': projectPath,
        'project_name': projectName,
        'compatible': compatible,
        'can_repair': canRepair,
        'issues': issues,
        'missing': missing,
      };
}

class FlutterProjectRepairResult {
  FlutterProjectRepairResult({
    required this.applied,
    required this.actions,
    required this.analysis,
  });

  final bool applied;
  final List<String> actions;
  final FlutterProjectAnalysis analysis;

  Map<String, dynamic> toJson() => {
        'applied': applied,
        'actions': actions,
        'analysis': analysis.toJson(),
      };
}

String sanitizePubspecProjectName(String raw) {
  var name = raw.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]+'), '_');
  name = name.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
  if (name.isEmpty) name = 'my_app';
  if (RegExp(r'^\d').hasMatch(name)) name = 'app_$name';
  return name;
}

String? readPubspecName(Directory projectRoot) {
  final pubspec = File(p.join(projectRoot.path, 'pubspec.yaml'));
  if (!pubspec.existsSync()) return null;
  final match = RegExp(r'^name:\s*(\S+)', multiLine: true)
      .firstMatch(pubspec.readAsStringSync());
  return match?.group(1);
}

FlutterProjectAnalysis analyzeFlutterProjectStructure(Directory projectRoot) {
  final root = projectRoot.absolute;
  final issues = <String>[];
  final missing = <String>[];

  final pubspecFile = File(p.join(root.path, 'pubspec.yaml'));
  final hasPubspec = pubspecFile.existsSync();
  if (!hasPubspec) {
    missing.add('pubspec.yaml');
    issues.add('Missing pubspec.yaml');
  }

  var projectName = readPubspecName(root) ?? sanitizePubspecProjectName(p.basename(root.path));

  if (hasPubspec && !isFlutterSdkProject(root)) {
    missing.add('flutter_sdk_dependency');
    issues.add('pubspec.yaml does not declare a Flutter SDK dependency');
  }

  final libDir = Directory(p.join(root.path, 'lib'));
  if (!libDir.existsSync()) {
    missing.add('lib/');
    issues.add('Missing lib/ directory');
  }

  final mainDart = File(p.join(root.path, 'lib/main.dart'));
  if (!mainDart.existsSync()) {
    missing.add('lib/main.dart');
    issues.add('Missing lib/main.dart');
  }

  for (final entry in const [
    ('android/', 'android/'),
    ('ios/', 'ios/'),
  ]) {
    if (!Directory(p.join(root.path, entry.$1)).existsSync()) {
      missing.add(entry.$2);
      // Platform folders are recommended but not required to open a project.
      issues.add('Optional: missing ${entry.$2} platform folder');
    }
  }

  final coreIssues = issues.where((issue) => !issue.startsWith('Optional:')).toList();
  final compatible = coreIssues.isEmpty;
  final effectivelyEmpty = root
      .listSync()
      .where((e) => !p.basename(e.path).startsWith('.'))
      .isEmpty;
  final canRepair = !compatible &&
      (hasPubspec || libDir.existsSync() || effectivelyEmpty);

  return FlutterProjectAnalysis(
    projectPath: root.path,
    projectName: projectName,
    compatible: compatible,
    canRepair: canRepair,
    issues: issues,
    missing: missing,
  );
}

Future<void> requireFlutterOnMachine() async {
  detectFlutter();
  final flutter = detectFlutter();
  final version = await Process.run(
    flutter.executable,
    flutter.buildArgs(['--version']),
  );
  if (version.exitCode != 0) {
    throw StateError(
      'Flutter is installed but `flutter --version` failed. Run flutter doctor.',
    );
  }
}

Future<FlutterProjectRepairResult> repairFlutterProjectStructure(
  Directory projectRoot,
) async {
  await requireFlutterOnMachine();
  final flutter = detectFlutter();
  final root = projectRoot.absolute;
  final actions = <String>[];

  final pubspecFile = File(p.join(root.path, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) {
    final name = sanitizePubspecProjectName(p.basename(root.path));
    await pubspecFile.writeAsString(_minimalPubspec(name));
    actions.add('Created pubspec.yaml');
  }

  if (!isFlutterSdkProject(root)) {
    await _ensureFlutterInPubspec(root);
    actions.add('Added Flutter SDK dependency to pubspec.yaml');
  }

  final platforms = <String>[];
  if (!Directory(p.join(root.path, 'android')).existsSync()) {
    platforms.add('android');
  }
  if (!Directory(p.join(root.path, 'ios')).existsSync()) {
    platforms.add('ios');
  }
  if (Platform.isMacOS && !Directory(p.join(root.path, 'macos')).existsSync()) {
    platforms.add('macos');
  }

  final needsFlutterCreate = platforms.isNotEmpty ||
      !File(p.join(root.path, 'lib/main.dart')).existsSync() ||
      !Directory(p.join(root.path, 'lib')).existsSync();

  if (needsFlutterCreate) {
    final projectName =
        readPubspecName(root) ?? sanitizePubspecProjectName(p.basename(root.path));
    final args = <String>[
      'create',
      '.',
      '--project-name',
      projectName,
      if (platforms.isNotEmpty) '--platforms=${platforms.join(',')}',
    ];
    final result = await Process.run(
      flutter.executable,
      flutter.buildArgs(args),
      workingDirectory: root.path,
    );
    if (result.exitCode != 0) {
      final message = '${result.stderr}'.trim();
      throw StateError(
        message.isEmpty ? 'flutter create failed in ${root.path}' : message,
      );
    }
    actions.add('Ran flutter create . (${platforms.isEmpty ? 'scaffold files' : platforms.join(', ')})');
  }

  if (!File(p.join(root.path, 'lib/main.dart')).existsSync()) {
    await Directory(p.join(root.path, 'lib')).create(recursive: true);
    await File(p.join(root.path, 'lib/main.dart')).writeAsString(_defaultMainDart);
    actions.add('Created lib/main.dart');
  }

  final analysis = analyzeFlutterProjectStructure(root);
  return FlutterProjectRepairResult(
    applied: actions.isNotEmpty,
    actions: actions,
    analysis: analysis,
  );
}

Future<Directory> createFlutterProject({
  required Directory parentDirectory,
  required String projectName,
}) async {
  await requireFlutterOnMachine();
  final flutter = detectFlutter();
  final safeName = sanitizePubspecProjectName(projectName);
  final parent = parentDirectory.absolute;
  if (!parent.existsSync()) {
    await parent.create(recursive: true);
  }
  final target = Directory(p.join(parent.path, safeName));
  if (target.existsSync() && target.listSync().isNotEmpty) {
    throw StateError('Target already exists and is not empty: ${target.path}');
  }

  final platforms = Platform.isMacOS ? 'android,ios,macos' : 'android,ios';
  final result = await Process.run(
    flutter.executable,
    flutter.buildArgs([
      'create',
      '--project-name',
      safeName,
      '--platforms',
      platforms,
      target.path,
    ]),
  );
  if (result.exitCode != 0) {
    final message = '${result.stderr}'.trim();
    throw StateError(
      message.isEmpty ? 'flutter create failed for $safeName' : message,
    );
  }
  return target.absolute;
}

Future<void> _ensureFlutterInPubspec(Directory root) async {
  final pubspec = File(p.join(root.path, 'pubspec.yaml'));
  var content = pubspec.readAsStringSync();
  if (!content.contains('environment:')) {
    content += '\nenvironment:\n  sdk: ^3.5.0\n';
  }
  if (!RegExp(r'^\s*flutter\s*:', multiLine: true).hasMatch(content)) {
    if (!content.contains('dependencies:')) {
      content += '\ndependencies:\n';
    }
    content += '  flutter:\n    sdk: flutter\n';
  }
  if (!content.contains('flutter:')) {
    content += '\nflutter:\n  uses-material-design: true\n';
  }
  await pubspec.writeAsString(content);
}

String _minimalPubspec(String name) => '''
name: $name
description: A Flutter project scaffolded by Flutter Project Setup Toolkit.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.5.0

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

flutter:
  uses-material-design: true
''';

const _defaultMainDart = '''
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const Scaffold(
        body: Center(child: Text('Hello from Flutter Project Setup Toolkit')),
      ),
    );
  }
}
''';
