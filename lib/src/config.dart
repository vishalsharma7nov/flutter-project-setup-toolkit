import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'models.dart';
import 'project_root.dart';
import 'architecture/architecture_config.dart';
import 'api/api_config.dart';

const defaultVersionKeys = {
  'android_name': 'APP_VERSION_NAME',
  'android_code': 'APP_VERSION_CODE',
  'ios_marketing': 'BUNDLE_VERSION_STRING',
  'ios_build': 'BUNDLE_VERSION',
};

class ToolkitConfig {
  ToolkitConfig({
    required this.projectRoot,
    Map<String, String>? environments,
    Map<String, String>? versionKeys,
    List<MainDartEnvRule>? mainDartEnvRules,
    BuildConfig? build,
    this.defaultEnvironment,
    StateManagement? stateManagement,
    ArchitectureConfig? architecture,
    ApiConfig? api,
  })  : environments = environments ?? {},
        versionKeys = {...defaultVersionKeys, ...?versionKeys},
        mainDartEnvRules = mainDartEnvRules ?? [],
        build = build ?? const BuildConfig(),
        stateManagement = stateManagement ?? StateManagement.none,
        architecture = architecture ?? ArchitectureConfig.defaults(),
        api = api ?? ApiConfig.defaults();

  final Directory projectRoot;
  final Map<String, String> environments;
  final Map<String, String> versionKeys;
  final List<MainDartEnvRule> mainDartEnvRules;
  final BuildConfig build;
  final String? defaultEnvironment;
  final StateManagement stateManagement;
  final ArchitectureConfig architecture;
  final ApiConfig api;

  String get androidNameKey => versionKeys['android_name']!;
  String get androidCodeKey => versionKeys['android_code']!;
  String get iosMarketingKey => versionKeys['ios_marketing']!;
  String get iosBuildKey => versionKeys['ios_build']!;

  List<String> get versionKeyList => [
        androidNameKey,
        androidCodeKey,
        iosMarketingKey,
        iosBuildKey,
      ];

  File resolveEnvPath(String name) {
    final rel = environments[name];
    if (rel == null) {
      throw ArgumentError(
        "Unknown environment '$name'. Configure environments in release-toolkit.config.json.",
      );
    }
    final file = p.isAbsolute(rel) ? File(rel) : File(p.join(projectRoot.path, rel));
    return file.absolute;
  }

  String? resolveEnvFromMainDart() {
    final mainDart = File(p.join(projectRoot.path, 'lib', 'main.dart'));
    if (!mainDart.existsSync()) {
      return null;
    }
    final text = mainDart.readAsStringSync();
    for (final rule in mainDartEnvRules) {
      if (rule.match.isNotEmpty &&
          rule.environment.isNotEmpty &&
          text.contains(rule.match)) {
        return rule.environment;
      }
    }
    return null;
  }
}

ToolkitConfig loadConfig(Directory projectRoot, {File? configPath}) {
  final root = projectRoot.absolute;
  final path = _findConfigPath(root, configPath);
  if (path == null) {
    return ToolkitConfig(projectRoot: root);
  }
  final raw = path.readAsStringSync();
  final Map<String, dynamic> decoded;
  try {
    decoded = jsonDecode(raw) as Map<String, dynamic>;
  } on FormatException catch (e) {
    throw StateError(
      'Invalid release-toolkit.config.json in ${projectRoot.path}: $e',
    );
  }
  final environments = Map<String, String>.from(
    (decoded['environments'] as Map?)?.cast<String, String>() ?? {},
  );
  final versionKeys = Map<String, String>.from(
    (decoded['version_keys'] as Map?)?.cast<String, String>() ?? {},
  );
  final rules = <MainDartEnvRule>[];
  for (final item in (decoded['main_dart_env_rules'] as List?) ?? []) {
    final map = item as Map<String, dynamic>;
    rules.add(MainDartEnvRule(
      match: map['match'] as String? ?? '',
      environment: map['environment'] as String? ?? '',
    ));
  }
  final buildRaw = decoded['build'] as Map<String, dynamic>?;
  final build = BuildConfig(
    androidFlavor: buildRaw?['android_flavor'] as String?,
    iosFlavor: buildRaw?['ios_flavor'] as String?,
    iosScheme: buildRaw?['ios_scheme'] as String? ?? 'Runner',
    openOrganizer: buildRaw?['open_organizer'] as bool? ?? true,
  );
  return ToolkitConfig(
    projectRoot: root,
    environments: environments,
    versionKeys: versionKeys,
    mainDartEnvRules: rules,
    build: build,
    defaultEnvironment: decoded['default_environment'] as String?,
    stateManagement:
        StateManagement.parse(decoded['state_management'] as String?) ??
            StateManagement.none,
    architecture: ArchitectureConfig.fromJson(
      decoded['architecture'] as Map<String, dynamic>?,
    ),
    api: ApiConfig.fromJson(decoded['api'] as Map<String, dynamic>?),
  );
}

File? _findConfigPath(Directory projectRoot, File? explicit) {
  if (explicit != null) {
    return explicit.existsSync() ? explicit.absolute : null;
  }
  final candidate = File(p.join(projectRoot.path, 'release-toolkit.config.json'));
  return candidate.existsSync() ? candidate : null;
}

List<MapEntry<String, File>> resolveEnvTargets(
  ToolkitConfig config,
  String env,
  File? envFile,
) {
  if (envFile != null) {
    final file = envFile.isAbsolute
        ? envFile
        : File(p.join(config.projectRoot.path, envFile.path));
    return [MapEntry('custom', file.absolute)];
  }
  if (env == 'both') {
    return config.environments.keys
        .map((name) => MapEntry(name, config.resolveEnvPath(name)))
        .toList();
  }
  if (!config.environments.containsKey(env)) {
    final names = config.environments.keys.join(', ');
    throw ArgumentError("Unknown environment '$env'. Configured: $names");
  }
  return [MapEntry(env, config.resolveEnvPath(env))];
}

Directory resolveProjectRoot(String? projectArg) {
  if (projectArg != null && projectArg.isNotEmpty) {
    return Directory(projectArg).absolute;
  }
  return findProjectRoot(Directory.current);
}

void validateFlutterProject(Directory projectRoot) {
  final pubspec = File(p.join(projectRoot.path, 'pubspec.yaml'));
  if (!pubspec.existsSync()) {
    throw StateError(
      'Not a Flutter project: pubspec.yaml not found in ${projectRoot.path}',
    );
  }
}

/// True when [pubspec.yaml] declares a Flutter SDK or `flutter:` dependency.
bool isFlutterSdkProject(Directory projectRoot) {
  validateFlutterProject(projectRoot);
  final content =
      File(p.join(projectRoot.path, 'pubspec.yaml')).readAsStringSync();
  return RegExp(r'^\s*flutter\s*:', multiLine: true).hasMatch(content) ||
      RegExp(r'sdk:\s*flutter', multiLine: true).hasMatch(content);
}

void validateFlutterSdkProject(Directory projectRoot) {
  if (!isFlutterSdkProject(projectRoot)) {
    throw StateError(
      'Not a Flutter app: pubspec.yaml has no Flutter SDK dependency in '
      '${projectRoot.path}',
    );
  }
}
