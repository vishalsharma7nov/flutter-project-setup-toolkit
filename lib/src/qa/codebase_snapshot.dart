import 'dart:io';

import 'package:path/path.dart' as p;

import '../architecture/micro_feature_scaffold.dart';
import '../classify.dart';
import '../models.dart';

/// Lightweight static scan of a Flutter project when git history is missing.
///
/// Infers rough purpose, feature areas, screens, and QA focus from folder
/// layout, pubspec, README, and common Dart naming patterns.
class CodebaseSnapshot {
  const CodebaseSnapshot({
    required this.projectName,
    required this.roughPurpose,
    required this.featureModules,
    required this.screens,
    required this.routes,
    required this.layers,
    required this.keyDependencies,
    required this.platforms,
    required this.dartFiles,
    required this.testFiles,
    required this.understandingNotes,
    required this.inventory,
  });

  final String projectName;
  final String roughPurpose;
  final List<String> featureModules;
  final List<String> screens;
  final List<String> routes;
  final List<String> layers;
  final List<String> keyDependencies;
  final List<String> platforms;
  final List<String> dartFiles;
  final List<String> testFiles;
  final List<String> understandingNotes;
  final List<FileChange> inventory;

  Map<String, dynamic> toJson() => {
        'project_name': projectName,
        'rough_purpose': roughPurpose,
        'feature_modules': featureModules,
        'screens': screens,
        'routes': routes,
        'layers': layers,
        'key_dependencies': keyDependencies,
        'platforms': platforms,
        'dart_file_count': dartFiles.length,
        'test_file_count': testFiles.length,
        'understanding_notes': understandingNotes,
      };
}

/// Scan [projectRoot] and build a [CodebaseSnapshot].
CodebaseSnapshot analyzeCodebase(Directory projectRoot) {
  final root = projectRoot.absolute;
  final projectName = readProjectPackageName(root);
  final pubspecText = _readIfExists(File(p.join(root.path, 'pubspec.yaml')));
  final readmeText = _readIfExists(File(p.join(root.path, 'README.md'))) ??
      _readIfExists(File(p.join(root.path, 'readme.md')));

  final libDir = Directory(p.join(root.path, 'lib'));
  final dartFiles = <String>[];
  if (libDir.existsSync()) {
    dartFiles.addAll(
      libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !shouldIgnorePath(_rel(root, f.path)))
          .map((f) => _rel(root, f.path)),
    );
    dartFiles.sort();
  }

  final testDir = Directory(p.join(root.path, 'test'));
  final testFiles = <String>[];
  if (testDir.existsSync()) {
    testFiles.addAll(
      testDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .map((f) => _rel(root, f.path)),
    );
    testFiles.sort();
  }

  final featureModules = _featureModules(root, dartFiles);
  final screens = _screensFromPaths(dartFiles);
  final routes = _extractRoutes(dartFiles, root);
  final layers = _detectLayers(dartFiles);
  final keyDependencies = _keyDependencies(pubspecText);
  final platforms = _platformFolders(root);
  final description = _pubspecDescription(pubspecText);
  final readmeLead = _readmeLead(readmeText);
  final understandingNotes = _buildUnderstandingNotes(
    dartFiles: dartFiles,
    testFiles: testFiles,
    featureModules: featureModules,
    screens: screens,
    routes: routes,
    layers: layers,
    keyDependencies: keyDependencies,
    platforms: platforms,
    root: root,
  );
  final roughPurpose = _roughPurpose(
    projectName: projectName,
    description: description,
    readmeLead: readmeLead,
    featureModules: featureModules,
    screens: screens,
    keyDependencies: keyDependencies,
  );

  final inventory = <FileChange>[
    ...dartFiles.map((path) => FileChange('P', path)),
    ...testFiles.map((path) => FileChange('P', path)),
  ];

  return CodebaseSnapshot(
    projectName: projectName,
    roughPurpose: roughPurpose,
    featureModules: featureModules,
    screens: screens,
    routes: routes,
    layers: layers,
    keyDependencies: keyDependencies,
    platforms: platforms,
    dartFiles: dartFiles,
    testFiles: testFiles,
    understandingNotes: understandingNotes,
    inventory: inventory,
  );
}

String _rel(Directory root, String path) =>
    p.relative(path, from: root.path).replaceAll('\\', '/');

String? _readIfExists(File file) =>
    file.existsSync() ? file.readAsStringSync() : null;

String? _pubspecDescription(String? pubspec) {
  if (pubspec == null) return null;
  final match =
      RegExp(r'^description:\s*(.+)$', multiLine: true).firstMatch(pubspec);
  return match?.group(1)?.trim();
}

String? _readmeLead(String? readme) {
  if (readme == null || readme.trim().isEmpty) return null;
  final lines = readme
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty && !l.startsWith('#'))
      .take(3)
      .join(' ');
  return lines.length > 280 ? '${lines.substring(0, 277)}…' : lines;
}

List<String> _featureModules(Directory root, List<String> dartFiles) {
  final featuresDir = Directory(p.join(root.path, 'lib', 'features'));
  if (featuresDir.existsSync()) {
    return featuresDir
        .listSync()
        .whereType<Directory>()
        .map((d) => p.basename(d.path))
        .where((name) => !name.startsWith('.'))
        .toList()
      ..sort();
  }
  final fromPaths = <String>{};
  for (final path in dartFiles) {
    final match = RegExp(r'^lib/features/([^/]+)/').firstMatch(path);
    if (match != null) fromPaths.add(match.group(1)!);
  }
  return fromPaths.toList()..sort();
}

List<String> _screensFromPaths(List<String> dartFiles) {
  final screens = <String>{};
  for (final path in dartFiles) {
    final pageMatch = RegExp(r'/([^/]+)_page\.dart$').firstMatch(path);
    if (pageMatch != null) {
      screens.add(_titleCase(pageMatch.group(1)!));
      continue;
    }
    final screenMatch = RegExp(r'/([^/]+)_screen\.dart$').firstMatch(path);
    if (screenMatch != null) {
      screens.add(_titleCase(screenMatch.group(1)!));
    }
  }
  return screens.toList()..sort();
}

List<String> _extractRoutes(List<String> dartFiles, Directory root) {
  final routes = <String>{};
  final routeFiles = dartFiles.where(
    (path) =>
        path.contains('route') ||
        path.endsWith('router.dart') ||
        path.contains('/routes/'),
  );
  final routeName = RegExp(r'RoutesName\.(\w+)');
  final goRoute = RegExp("path:\\s*['\"]([^'\"]+)['\"]");
  final namedRoute = RegExp("['\"](/[^'\"]+)['\"]");

  for (final rel in routeFiles) {
    final content = File(p.join(root.path, rel)).readAsStringSync();
    for (final match in routeName.allMatches(content)) {
      routes.add(match.group(1)!);
    }
    for (final match in goRoute.allMatches(content)) {
      routes.add(match.group(1)!);
    }
    for (final match in namedRoute.allMatches(content)) {
      final value = match.group(1)!;
      if (value.startsWith('/')) routes.add(value);
    }
  }
  return routes.toList()..sort();
}

List<String> _detectLayers(List<String> dartFiles) {
  final layers = <String>{};
  for (final path in dartFiles) {
    if (path.contains('/presentation/')) layers.add('presentation');
    if (path.contains('/domain/')) layers.add('domain');
    if (path.contains('/data/')) layers.add('data');
    if (path.contains('/bloc/') || path.endsWith('_bloc.dart')) {
      layers.add('bloc');
    }
    if (path.contains('provider') || path.endsWith('_provider.dart')) {
      layers.add('provider/riverpod');
    }
    if (path.contains('/widgets/')) layers.add('widgets');
    if (path.contains('/services/') || path.endsWith('_service.dart')) {
      layers.add('services');
    }
    if (path.contains('/repositories/') || path.endsWith('_repository.dart')) {
      layers.add('repositories');
    }
  }
  return layers.toList()..sort();
}

List<String> _keyDependencies(String? pubspec) {
  if (pubspec == null) return [];
  const interesting = {
    'flutter_bloc',
    'bloc',
    'riverpod',
    'flutter_riverpod',
    'provider',
    'dio',
    'http',
    'retrofit',
    'graphql',
    'grpc',
    'firebase_core',
    'firebase_auth',
    'cloud_firestore',
    'go_router',
    'auto_route',
    'get',
    'hive',
    'sqflite',
    'shared_preferences',
    'connectivity_plus',
  };
  final found = <String>[];
  for (final dep in interesting) {
    if (RegExp('^\\s*$dep:', multiLine: true).hasMatch(pubspec)) {
      found.add(dep);
    }
  }
  return found;
}

List<String> _platformFolders(Directory root) {
  final platforms = <String>[];
  if (Directory(p.join(root.path, 'android')).existsSync()) {
    platforms.add('Android');
  }
  if (Directory(p.join(root.path, 'ios')).existsSync()) platforms.add('iOS');
  if (Directory(p.join(root.path, 'web')).existsSync()) platforms.add('Web');
  if (Directory(p.join(root.path, 'macos')).existsSync() ||
      Directory(p.join(root.path, 'windows')).existsSync() ||
      Directory(p.join(root.path, 'linux')).existsSync()) {
    platforms.add('Desktop');
  }
  if (platforms.isEmpty) platforms.add('Dart/UI');
  return platforms;
}

String _roughPurpose({
  required String projectName,
  required String? description,
  required String? readmeLead,
  required List<String> featureModules,
  required List<String> screens,
  required List<String> keyDependencies,
}) {
  final parts = <String>[];
  if (description != null && description.isNotEmpty && description != 'Demo') {
    parts.add(description);
  } else if (readmeLead != null && readmeLead.isNotEmpty) {
    parts.add(readmeLead);
  } else {
    parts.add('Flutter app `$projectName`');
  }
  if (featureModules.isNotEmpty) {
    parts.add('Modules: ${featureModules.join(', ')}');
  } else if (screens.isNotEmpty) {
    parts.add('Screens detected: ${screens.take(6).join(', ')}');
  }
  if (keyDependencies.isNotEmpty) {
    parts.add('Stack hints: ${keyDependencies.take(5).join(', ')}');
  }
  return parts.join(' · ');
}

List<String> _buildUnderstandingNotes({
  required List<String> dartFiles,
  required List<String> testFiles,
  required List<String> featureModules,
  required List<String> screens,
  required List<String> routes,
  required List<String> layers,
  required List<String> keyDependencies,
  required List<String> platforms,
  required Directory root,
}) {
  final notes = <String>[
    'Generated from codebase scan — no git commit compare available.',
    '${dartFiles.length} Dart file(s) under lib/, ${testFiles.length} test file(s).',
  ];
  if (featureModules.isNotEmpty) {
    notes.add(
      'Feature-style folders: ${featureModules.join(', ')} — smoke each flow.',
    );
  }
  if (screens.isNotEmpty) {
    notes.add('UI surfaces: ${screens.join(', ')}.');
  }
  if (routes.isNotEmpty) {
    notes.add('Routes/paths found: ${routes.take(8).join(', ')}.');
  }
  if (layers.isNotEmpty) {
    notes.add('Architecture layers present: ${layers.join(', ')}.');
  }
  if (keyDependencies.isNotEmpty) {
    notes.add('Notable packages: ${keyDependencies.join(', ')}.');
  }
  notes.add('Target platforms: ${platforms.join(', ')}.');

  final mainFile = File(p.join(root.path, 'lib', 'main.dart'));
  if (mainFile.existsSync()) {
    final mainText = mainFile.readAsStringSync();
    if (mainText.contains('MaterialApp')) notes.add('Entry uses MaterialApp.');
    if (mainText.contains('CupertinoApp')) {
      notes.add('Entry uses CupertinoApp.');
    }
    if (mainText.contains('GoRouter')) notes.add('Routing via GoRouter.');
    if (mainText.contains('Firebase')) notes.add('Firebase initialized at startup.');
  }

  notes.add(
    'Use this handoff for exploratory QA when commit history is unknown or missing.',
  );
  return notes;
}

String _titleCase(String raw) {
  return raw
      .split('_')
      .where((p) => p.isNotEmpty)
      .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
      .join(' ');
}
