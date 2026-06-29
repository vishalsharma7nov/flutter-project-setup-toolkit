import 'dart:io';

import 'package:path/path.dart' as p;

import '../api/api_config.dart';
import '../models.dart';
import 'architecture_config.dart';
import 'architecture_layers.dart';
import 'architecture_preset.dart';
import 'feature_naming.dart';

/// Relative paths created when bootstrapping a micro-feature monorepo.
List<String> microFeatureBootstrapPaths({required String projectName}) {
  return [
    'melos.yaml',
    'apps/shell/pubspec.yaml',
    'apps/shell/lib/main.dart',
    'packages/',
  ];
}

String microFeatureMelosYaml(String projectName) {
  final workspace = _sanitizePackageName(projectName);
  return '''
name: ${workspace}_workspace

packages:
  - apps/**
  - packages/**
''';
}

String microFeatureShellPubspec() {
  return '''
name: shell
description: Host application for micro-feature packages
publish_to: none
version: 0.0.1

environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=3.16.0"

dependencies:
  flutter:
    sdk: flutter

flutter:
  uses-material-design: true
''';
}

String microFeatureShellMain() {
  return '''
import 'package:flutter/material.dart';

void main() {
  runApp(const ShellApp());
}

class ShellApp extends StatelessWidget {
  const ShellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Micro-feature shell app')),
      ),
    );
  }
}
''';
}

String microFeaturePackagePubspec(String featureName) {
  final packageName = _sanitizePackageName(featureName);
  return '''
name: $packageName
description: $featureName feature package
publish_to: none
version: 0.0.1

environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=3.16.0"

dependencies:
  flutter:
    sdk: flutter

flutter:
  uses-material-design: true
''';
}

String microFeaturePackageBarrel(String featureName, String filePrefix) {
  final packageName = _sanitizePackageName(featureName);
  return '''
library $packageName;

export 'src/presentation/pages/${filePrefix}page.dart';
''';
}

String _sanitizePackageName(String raw) {
  var name = raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]+'), '_');
  name = name.replaceAll(RegExp(r'^_+|_+$'), '');
  name = name.replaceAll(RegExp(r'_+'), '_');
  if (name.isEmpty) return 'feature';
  if (RegExp(r'^[0-9]').hasMatch(name)) {
    name = 'pkg_$name';
  }
  return name;
}

Future<List<String>> scaffoldMicroFeaturePackage({
  required Directory projectRoot,
  required String featureName,
  required String filePrefix,
  required StateManagement stateManagement,
  required ArchitectureConfig architecture,
  required ApiConfig api,
  bool dryRun = false,
}) async {
  final createdPaths = <String>[];
  final packageRoot = p.join('packages', featureName);
  final srcRoot = p.join(packageRoot, 'lib', 'src');
  final displayRoot = packageRoot;

  final packageFiles = <String, String>{
    p.join(packageRoot, 'pubspec.yaml'): microFeaturePackagePubspec(featureName),
    p.join(packageRoot, 'lib', '$featureName.dart'):
        microFeaturePackageBarrel(featureName, filePrefix),
  };

  for (final entry in packageFiles.entries) {
    if (dryRun) {
      createdPaths.add(entry.key);
      continue;
    }
    final file = File(p.join(projectRoot.path, entry.key));
    if (file.existsSync()) continue;
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(entry.value);
    createdPaths.add(entry.key);
  }

  for (final dir in architectureFeatureDirectories(
    preset: ArchitecturePreset.featureFirstClean,
    stateManagement: stateManagement,
    layers: architecture.layers,
  )) {
    final relative = p.join(srcRoot, dir);
    if (dryRun) {
      createdPaths.add('$relative/');
      continue;
    }
    Directory(p.join(projectRoot.path, relative)).createSync(recursive: true);
    createdPaths.add('$relative/');
  }

  for (final relativeFile in architectureFeatureFilePaths(
    preset: ArchitecturePreset.featureFirstClean,
    prefix: filePrefix,
    stateManagement: stateManagement,
    layers: architecture.layers,
    api: api,
  )) {
    final relative = p.join(srcRoot, relativeFile);
    if (dryRun) {
      createdPaths.add(relative);
      continue;
    }
    final file = File(p.join(projectRoot.path, relative));
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    if (!file.existsSync()) {
      file.writeAsStringSync('');
      createdPaths.add(relative);
    }
  }

  return createdPaths;
}

List<String> microFeaturePreviewPaths({
  required String featureName,
  required String filePrefix,
  required StateManagement stateManagement,
  required ArchitectureConfig architecture,
  required ApiConfig api,
}) {
  final packageRoot = p.join('packages', featureName);
  final srcRoot = p.join(packageRoot, 'lib', 'src');
  return [
    p.join(packageRoot, 'pubspec.yaml'),
    p.join(packageRoot, 'lib', '$featureName.dart'),
    ...architectureFeatureFilePaths(
      preset: ArchitecturePreset.featureFirstClean,
      prefix: filePrefix,
      stateManagement: stateManagement,
      layers: architecture.layers,
      api: api,
    ).map((file) => p.join(srcRoot, file)),
  ];
}

String readProjectPackageName(Directory projectRoot) {
  final pubspec = File(p.join(projectRoot.path, 'pubspec.yaml'));
  if (!pubspec.existsSync()) return 'app';
  for (final line in pubspec.readAsLinesSync()) {
    final match = RegExp(r'^name:\s*(\S+)').firstMatch(line.trim());
    if (match != null) return match.group(1)!;
  }
  return 'app';
}
