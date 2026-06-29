import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'config.dart';
import 'feature_scaffold.dart';
import 'interactive.dart';
import 'ios_xcode.dart';
import 'models.dart';
import 'state_management.dart';
import 'toolkit_install.dart';
import 'architecture/architecture_compatibility.dart';
import 'architecture/architecture_config.dart';
import 'architecture/architecture_preset.dart';
import 'architecture/project_bootstrap.dart';
import 'api/api_config.dart';
import 'api/api_packages.dart';
import 'api/api_protocol.dart';
import 'api/api_scaffold.dart';
import 'architecture/architecture_guardrails.dart';
import 'ci/github_actions_template.dart';

enum EnvPreset {
  devProd(['dev', 'prod']),
  devStagingProd(['dev', 'staging', 'prod']),
  custom([]);

  const EnvPreset(this.names);
  final List<String> names;
}

enum EnvDirectoryStyle {
  dotEnv,
  dotSecrets,
  custom,
}

class SetupPlan {
  SetupPlan({
    required this.projectRoot,
    required this.environments,
    required this.defaultEnvironment,
    required this.versionKeys,
    required this.build,
    required this.mainDartEnvRules,
    required this.toolkitMode,
    required this.createEnvTemplates,
    required this.createScripts,
    this.createCiWorkflow = false,
    this.localToolkitPath,
    this.toolkitInstallPath,
    this.featureToScaffold,
    this.featureBasePath = 'lib/features',
    this.stateManagement = StateManagement.none,
    this.architecture = const ArchitectureConfig(),
    this.api = const ApiConfig(),
    this.pubspecVersionConstraint = '^0.1.0',
  });

  final Directory projectRoot;
  final Map<String, String> environments;
  final String defaultEnvironment;
  final Map<String, String> versionKeys;
  final BuildConfig build;
  final List<MainDartEnvRule> mainDartEnvRules;
  final ToolkitInstallMode toolkitMode;
  final bool createEnvTemplates;
  final bool createScripts;
  final bool createCiWorkflow;
  final String? localToolkitPath;
  final String? toolkitInstallPath;
  final String? featureToScaffold;
  final String featureBasePath;
  final StateManagement stateManagement;
  final ArchitectureConfig architecture;
  final ApiConfig api;
  final String pubspecVersionConstraint;

  Map<String, dynamic> toConfigJson() {
    return {
      'default_environment': defaultEnvironment,
      'state_management': stateManagement.name,
      'architecture': architecture.toJson(),
      'api': api.toJson(),
      'environments': environments,
      'version_keys': versionKeys,
      'build': {
        'android_flavor': build.androidFlavor,
        'ios_flavor': build.iosFlavor,
        'ios_scheme': build.iosScheme,
        'open_organizer': build.openOrganizer,
      },
      if (mainDartEnvRules.isNotEmpty)
        'main_dart_env_rules': mainDartEnvRules
            .map((rule) => {
                  'match': rule.match,
                  'environment': rule.environment,
                })
            .toList(),
    };
  }

  SetupPlan copyWith({
    Map<String, String>? environments,
    String? defaultEnvironment,
    Map<String, String>? versionKeys,
    BuildConfig? build,
    List<MainDartEnvRule>? mainDartEnvRules,
    ToolkitInstallMode? toolkitMode,
    bool? createEnvTemplates,
    bool? createScripts,
    bool? createCiWorkflow,
    String? localToolkitPath,
    String? toolkitInstallPath,
    String? featureToScaffold,
    String? featureBasePath,
    StateManagement? stateManagement,
    ArchitectureConfig? architecture,
    ApiConfig? api,
    bool clearFeatureToScaffold = false,
    bool clearLocalToolkitPath = false,
    bool clearToolkitInstallPath = false,
  }) {
    return SetupPlan(
      projectRoot: projectRoot,
      environments: environments ?? this.environments,
      defaultEnvironment: defaultEnvironment ?? this.defaultEnvironment,
      versionKeys: versionKeys ?? this.versionKeys,
      build: build ?? this.build,
      mainDartEnvRules: mainDartEnvRules ?? this.mainDartEnvRules,
      toolkitMode: toolkitMode ?? this.toolkitMode,
      createEnvTemplates: createEnvTemplates ?? this.createEnvTemplates,
      createScripts: createScripts ?? this.createScripts,
      createCiWorkflow: createCiWorkflow ?? this.createCiWorkflow,
      localToolkitPath:
          clearLocalToolkitPath ? null : (localToolkitPath ?? this.localToolkitPath),
      toolkitInstallPath: clearToolkitInstallPath
          ? null
          : (toolkitInstallPath ?? this.toolkitInstallPath),
      featureToScaffold: clearFeatureToScaffold
          ? null
          : (featureToScaffold ?? this.featureToScaffold),
      featureBasePath: featureBasePath ?? this.featureBasePath,
      stateManagement: stateManagement ?? this.stateManagement,
      architecture: architecture ?? this.architecture,
      api: api ?? this.api,
      pubspecVersionConstraint: pubspecVersionConstraint,
    );
  }
}

List<MainDartEnvRule> detectMainDartEnvRules(Directory projectRoot) {
  final mainDart = File(p.join(projectRoot.path, 'lib', 'main.dart'));
  if (!mainDart.existsSync()) {
    return [];
  }
  final text = mainDart.readAsStringSync();
  final rules = <MainDartEnvRule>[];
  final patterns = [
    (r'ConfigEnvironment\.(\w+)', _mapConfigEnvironmentName),
    (r'Environment\.(\w+)', _mapEnvironmentName),
  ];
  for (final (pattern, mapper) in patterns) {
    for (final match in RegExp(pattern).allMatches(text)) {
      final envName = mapper(match.group(1)!);
      final snippet = match.group(0)!;
      final line = text
          .split('\n')
          .firstWhere((item) => item.contains(snippet), orElse: () => '');
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final rule = MainDartEnvRule(match: trimmed, environment: envName);
      if (!rules.any((item) => item.match == rule.match)) {
        rules.add(rule);
      }
    }
  }
  return rules;
}

String _mapConfigEnvironmentName(String value) {
  switch (value.toLowerCase()) {
    case 'production':
      return 'prod';
    case 'dev':
    case 'development':
    case 'staging':
    case 'local':
      return 'dev';
    default:
      return value.toLowerCase();
  }
}

String _mapEnvironmentName(String value) {
  switch (value.toLowerCase()) {
    case 'production':
      return 'prod';
    case 'development':
      return 'dev';
    case 'staging':
      return 'staging';
    default:
      return value.toLowerCase();
  }
}

Map<String, String> defaultEnvPaths(
  List<String> envNames,
  EnvDirectoryStyle style,
  String customPrefix,
) {
  final paths = <String, String>{};
  for (final name in envNames) {
    paths[name] = _defaultPathForEnv(name, style, customPrefix);
  }
  return paths;
}

String _defaultPathForEnv(
  String name,
  EnvDirectoryStyle style,
  String customPrefix,
) {
  switch (style) {
    case EnvDirectoryStyle.dotEnv:
      switch (name) {
        case 'dev':
          return '.env/development.env';
        case 'staging':
          return '.env/staging.env';
        case 'prod':
          return '.env/production.env';
        default:
          return '.env/$name.env';
      }
    case EnvDirectoryStyle.dotSecrets:
      switch (name) {
        case 'dev':
          return '.secrets/app.local.env';
        case 'staging':
          return '.secrets/app.staging.env';
        case 'prod':
          return '.secrets/app.prod.env';
        default:
          return '.secrets/app.$name.env';
      }
    case EnvDirectoryStyle.custom:
      final prefix = customPrefix.endsWith('/')
          ? customPrefix.substring(0, customPrefix.length - 1)
          : customPrefix;
      return '$prefix/$name.env';
  }
}

String envTemplateContent(
  Map<String, String> versionKeys, {
  ApiConfig? api,
}) {
  final apiLine = api?.envLineForProtocol();
  return '''
# Generated by $toolkitPackageName setup
${versionKeys['android_name']}=1.0.0
${versionKeys['android_code']}=1
${versionKeys['ios_marketing']}=1.0.0
${versionKeys['ios_build']}=1
${apiLine ?? ''}
''';
}

SetupPlan buildSetupPlanFromAnswers({
  required Directory projectRoot,
  required List<String> envNames,
  required Map<String, String> environments,
  required String defaultEnvironment,
  required Map<String, String> versionKeys,
  required BuildConfig build,
  required List<MainDartEnvRule> mainDartEnvRules,
  required ToolkitInstallMode toolkitMode,
  required bool createEnvTemplates,
  required bool createScripts,
  String? localToolkitPath,
  String? toolkitInstallPath,
  String? featureToScaffold,
  String featureBasePath = 'lib/features',
  StateManagement stateManagement = StateManagement.none,
  ArchitectureConfig architecture = const ArchitectureConfig(),
  ApiConfig api = const ApiConfig(),
}) {
  if (!envNames.contains(defaultEnvironment)) {
    throw ArgumentError(
      "default environment '$defaultEnvironment' is not in configured environments",
    );
  }
  return SetupPlan(
    projectRoot: projectRoot,
    environments: environments,
    defaultEnvironment: defaultEnvironment,
    versionKeys: versionKeys,
    build: build,
    mainDartEnvRules: mainDartEnvRules,
    toolkitMode: toolkitMode,
    createEnvTemplates: createEnvTemplates,
    createScripts: createScripts,
    localToolkitPath: localToolkitPath,
    toolkitInstallPath: toolkitInstallPath,
    featureToScaffold: featureToScaffold,
    featureBasePath: featureBasePath,
    stateManagement: stateManagement,
    architecture: architecture,
    api: api,
  );
}

ToolkitInstallPlan toolkitInstallPlanFrom(SetupPlan plan) {
  return ToolkitInstallPlan(
    projectRoot: plan.projectRoot,
    mode: plan.toolkitMode,
    localToolkitPath: plan.localToolkitPath,
    toolkitInstallPath: plan.toolkitInstallPath,
    pubspecVersionConstraint: plan.pubspecVersionConstraint,
  );
}

Future<SetupPlan> collectSetupPlanInteractive({
  required Directory projectRoot,
  bool assumeYes = false,
}) async {
  validateFlutterProject(projectRoot);
  print('');
  print('=== $toolkitPackageName setup ===');
  print('Project: ${projectRoot.path}');
  print('');

  final presetChoice = assumeYes
      ? EnvPreset.devProd
      : _envPresetFromLabel(
          promptChoiceValue(
            'Which environments do you need?',
            [
              'dev + prod (typical)',
              'dev + staging + prod',
              'custom names',
            ],
          ),
        );

  final envNames = presetChoice == EnvPreset.custom
      ? _customEnvNames(assumeYes)
      : presetChoice.names;

  final dirStyle = assumeYes
      ? EnvDirectoryStyle.dotEnv
      : _dirStyleFromLabel(
          promptChoiceValue(
            'Where should dart-define env files live?',
            [
              '.env/ (recommended for local files)',
              '.secrets/ (gitignored secrets folder)',
              'custom directory',
            ],
          ),
        );

  final customPrefix = dirStyle == EnvDirectoryStyle.custom && !assumeYes
      ? promptLine('Env directory prefix', defaultValue: 'config/env')
      : 'config/env';

  var environments = defaultEnvPaths(envNames, dirStyle, customPrefix);
  if (!assumeYes && presetChoice != EnvPreset.custom) {
    print('');
    print('Env file paths:');
    for (final entry in environments.entries) {
      print('  ${entry.key}: ${entry.value}');
    }
    if (promptYesNo('Customize individual env file paths?', defaultYes: false)) {
      environments = _customizeEnvPaths(envNames, environments);
    }
  }

  final defaultEnvironment = assumeYes
      ? envNames.first
      : promptChoiceValue(
          'Which environment will you work on most often?',
          envNames,
          defaultIndex: envNames.indexOf('dev').clamp(0, envNames.length - 1),
        );

  final versionKeys = Map<String, String>.from(defaultVersionKeys);
  if (!assumeYes &&
      !promptYesNo('Use default version key names (APP_VERSION_NAME, etc.)?', defaultYes: true)) {
    versionKeys['android_name'] =
        promptLine('Android marketing version key', defaultValue: versionKeys['android_name']);
    versionKeys['android_code'] =
        promptLine('Android version code key', defaultValue: versionKeys['android_code']);
    versionKeys['ios_marketing'] =
        promptLine('iOS marketing version key', defaultValue: versionKeys['ios_marketing']);
    versionKeys['ios_build'] =
        promptLine('iOS build number key', defaultValue: versionKeys['ios_build']);
  }

  String? iosFlavor;
  String? androidFlavor;
  var iosScheme = detectIosBuildSettings(projectRoot)?.suggestedScheme ?? 'Runner';
  if (!assumeYes) {
    final iosDetection = detectIosBuildSettings(projectRoot);
    if (iosDetection != null && iosDetection.appSchemes.isNotEmpty) {
      print('');
      print('Detected iOS Xcode schemes: ${iosDetection.appSchemes.join(', ')}');
      if (iosDetection.archiveName != null) {
        print('Archive name: ${iosDetection.archiveName}.xcarchive');
      }
      if (iosDetection.appSchemes.length == 1) {
        iosScheme = iosDetection.appSchemes.first;
        print('Using iOS scheme: $iosScheme');
      } else {
        iosScheme = promptChoiceValue(
          'Which Xcode scheme should iOS builds use?',
          iosDetection.appSchemes,
          defaultIndex: iosDetection.appSchemes
              .indexOf(iosDetection.suggestedScheme)
              .clamp(0, iosDetection.appSchemes.length - 1),
        );
      }
    }
    if (promptYesNo('Does your app use iOS build flavors?', defaultYes: false)) {
      iosFlavor = promptLine('iOS flavor name (must match an Xcode scheme)');
    }
    if (promptYesNo('Does your app use Android product flavors?', defaultYes: false)) {
      androidFlavor = promptLine('Android flavor name');
    }
  }

  var mainDartRules = detectMainDartEnvRules(projectRoot);
  if (!assumeYes && mainDartRules.isNotEmpty) {
    print('');
    print('Detected lib/main.dart environment rules:');
    for (final rule in mainDartRules) {
      print('  "${rule.match}" -> ${rule.environment}');
    }
    if (!promptYesNo('Add these to release-toolkit.config.json?', defaultYes: true)) {
      mainDartRules = [];
    }
  }

  final toolkitMode = assumeYes
      ? ToolkitInstallMode.devDependency
      : _toolkitModeFromLabel(
          promptChoiceValue(
            'How will you run the toolkit?',
            [
              'dev_dependency in pubspec.yaml (recommended)',
              'local clone (path to flutter-project-setup-toolkit)',
              'pub global activate',
            ],
          ),
        );

  String? localToolkitPath;
  if (toolkitMode == ToolkitInstallMode.localClone) {
    final detected = detectRunningToolkitRoot();
    final defaultPath = detected != null
        ? posixRelativePath(projectRoot, detected)
        : '../flutter-project-setup-toolkit';
    localToolkitPath = assumeYes
        ? defaultPath
        : promptLine(
            'Path to flutter-project-setup-toolkit',
            defaultValue: defaultPath,
          );
  }

  final createEnvTemplates = assumeYes
      ? true
      : promptYesNo('Create env file templates with version keys?', defaultYes: true);
  final createScripts = assumeYes
      ? true
      : promptYesNo('Create scripts/ wrapper scripts in your app?', defaultYes: true);

  String? toolkitInstallPath;
  if (toolkitMode == ToolkitInstallMode.devDependency) {
    toolkitInstallPath = resolveToolkitInstallPath(
      ToolkitInstallPlan(
        projectRoot: projectRoot,
        mode: toolkitMode,
      ),
    );
  }

  String? featureToScaffold;
  var featureBasePath = 'lib/features';
  var architecture = ArchitectureConfig.defaults();
  var api = ApiConfig.defaults();
  final stateManagement = assumeYes
      ? StateManagement.none
      : promptStateManagement();

  if (!assumeYes) {
    final archLabel = promptChoiceValue(
      'Project architecture preset',
      allScaffoldPresets().map((p) => p.label).toList(),
      defaultIndex: 0,
    );
    final preset = allScaffoldPresets().firstWhere(
      (p) => p.label == archLabel,
      orElse: () => ArchitecturePreset.featureFirstClean,
    );
    architecture = ArchitectureConfig(
      preset: preset,
      featureBasePath: preset.defaultFeatureBasePath,
      bootstrap: preset == ArchitecturePreset.microFeature
          ? const ArchitectureBootstrapConfig(melos: true)
          : const ArchitectureBootstrapConfig(),
      customTemplatePath: preset == ArchitecturePreset.custom
          ? promptLine(
              'Custom template JSON path (relative to project)',
              defaultValue: 'templates/architecture/custom_feature.example.json',
            )
          : null,
    );
    featureBasePath = architecture.featureBasePath;

    final apiLabel = promptChoiceValue(
      'Primary API / backend',
      [
        ApiProtocol.rest.label,
        ApiProtocol.grpc.label,
        ApiProtocol.graphql.label,
        ApiProtocol.localOnly.label,
        ApiProtocol.externalSdk.label,
      ],
      defaultIndex: 0,
    );
    final protocol = ApiProtocol.values.firstWhere(
      (p) => p.label == apiLabel,
      orElse: () => ApiProtocol.rest,
    );
    if (protocol == ApiProtocol.externalSdk) {
      final packageName = promptLine('External SDK package name');
      final gitUrl = promptLine('Git repository URL');
      api = ApiConfig(
        protocol: ApiProtocol.externalSdk,
        clientSource: ApiClientSource.externalSdk,
        externalSdk: ExternalSdkConfig(
          packageName: packageName,
          source: 'git',
          git: ExternalSdkGitSource(url: gitUrl, ref: 'main'),
        ),
      );
    } else {
      api = ApiConfig(protocol: protocol);
    }

    final warning = architectureCompatibilityWarning(
      preset: preset,
      stateManagement: stateManagement,
    );
    if (warning != null) {
      print('Note: ${warning.message}');
    }
  }

  if (!assumeYes &&
      promptYesNo('Scaffold a feature to start working on?', defaultYes: false)) {
    featureToScaffold = promptLine('What feature do you want to work on?');
    while (featureToScaffold == null || featureToScaffold.isEmpty) {
      featureToScaffold = promptLine('Feature name is required');
    }
    if (!promptYesNo('Use base path ${architecture.featureBasePath}/?', defaultYes: true)) {
      featureBasePath = promptLine('Base path', defaultValue: featureBasePath);
    }
  }

  return buildSetupPlanFromAnswers(
    projectRoot: projectRoot,
    envNames: envNames,
    environments: environments,
    defaultEnvironment: defaultEnvironment,
    versionKeys: versionKeys,
    build: BuildConfig(
      androidFlavor: androidFlavor,
      iosFlavor: iosFlavor,
      iosScheme: iosScheme,
    ),
    mainDartEnvRules: mainDartRules,
    toolkitMode: toolkitMode,
    createEnvTemplates: createEnvTemplates,
    createScripts: createScripts,
    localToolkitPath: localToolkitPath,
    toolkitInstallPath: toolkitInstallPath,
    featureToScaffold: featureToScaffold,
    featureBasePath: featureBasePath,
    stateManagement: stateManagement,
    architecture: architecture,
    api: api,
  );
}

SetupPlan buildSetupPlanNonInteractive({
  required Directory projectRoot,
  required String preset,
  required String envDir,
  required String defaultEnvironment,
  String? toolkitPath,
  String? makeFeature,
  String featureBasePath = 'lib/features',
  StateManagement stateManagement = StateManagement.none,
  String? architecturePreset,
  String? apiProtocol,
}) {
  validateFlutterProject(projectRoot);
  final envPreset = switch (preset) {
    'dev-staging-prod' => EnvPreset.devStagingProd,
    'custom' => EnvPreset.custom,
    _ => EnvPreset.devProd,
  };
  final envNames = envPreset.names.isEmpty ? ['dev', 'prod'] : envPreset.names;
  final style = switch (envDir) {
    '.secrets' => EnvDirectoryStyle.dotSecrets,
    'custom' => EnvDirectoryStyle.custom,
    _ => EnvDirectoryStyle.dotEnv,
  };
  final environments = defaultEnvPaths(envNames, style, envDir);
  final resolvedDefault = envNames.contains(defaultEnvironment)
      ? defaultEnvironment
      : envNames.first;
  final archPreset =
      ArchitecturePreset.parse(architecturePreset) ??
          ArchitecturePreset.defaultPreset;
  final arch = ArchitectureConfig(
    preset: archPreset,
    featureBasePath: archPreset.defaultFeatureBasePath,
  );
  final api = ApiConfig(
    protocol: ApiProtocol.parse(apiProtocol) ?? ApiProtocol.rest,
  );
  return buildSetupPlanFromAnswers(
    projectRoot: projectRoot,
    envNames: envNames,
    environments: environments,
    defaultEnvironment: resolvedDefault,
    versionKeys: Map<String, String>.from(defaultVersionKeys),
    build: BuildConfig(
      iosScheme: detectIosBuildSettings(projectRoot)?.suggestedScheme ?? 'Runner',
    ),
    mainDartEnvRules: detectMainDartEnvRules(projectRoot),
    toolkitMode: ToolkitInstallMode.devDependency,
    createEnvTemplates: true,
    createScripts: true,
    toolkitInstallPath: toolkitPath,
    featureToScaffold: makeFeature,
    featureBasePath: arch.featureBasePath,
    stateManagement: stateManagement,
    architecture: arch,
    api: api,
  );
}

EnvPreset _envPresetFromLabel(String label) {
  if (label.startsWith('dev + staging')) return EnvPreset.devStagingProd;
  if (label.startsWith('custom')) return EnvPreset.custom;
  return EnvPreset.devProd;
}

EnvDirectoryStyle _dirStyleFromLabel(String label) {
  if (label.startsWith('.secrets')) return EnvDirectoryStyle.dotSecrets;
  if (label.startsWith('custom')) return EnvDirectoryStyle.custom;
  return EnvDirectoryStyle.dotEnv;
}

ToolkitInstallMode _toolkitModeFromLabel(String label) {
  if (label.startsWith('local clone')) return ToolkitInstallMode.localClone;
  if (label.startsWith('pub global')) return ToolkitInstallMode.globalCli;
  return ToolkitInstallMode.devDependency;
}

List<String> _customEnvNames(bool assumeYes) {
  if (assumeYes) return ['dev', 'prod'];
  final raw = promptLine('Environment names (comma-separated)', defaultValue: 'dev,prod');
  final names = raw
      .split(',')
      .map((name) => name.trim().toLowerCase())
      .where((name) => name.isNotEmpty)
      .toList();
  if (names.isEmpty) {
    throw ArgumentError('At least one environment name is required');
  }
  return names;
}

Map<String, String> _customizeEnvPaths(
  List<String> envNames,
  Map<String, String> defaults,
) {
  final customized = <String, String>{};
  for (final name in envNames) {
    final path = promptLine(
      'Path for $name',
      defaultValue: defaults[name],
    );
    customized[name] = path.isEmpty ? defaults[name]! : path;
    if (!customized[name]!.endsWith('.env')) {
      print(
        '  Note: env paths usually end with .env (e.g. .env/production.env)',
      );
    }
  }
  return customized;
}

class SetupResult {
  SetupResult({
    required this.wroteConfig,
    required this.createdEnvFiles,
    required this.createdScripts,
    required this.skipped,
    this.toolkitInstall,
    this.featureScaffold,
    this.stateManagementApply,
  });

  final bool wroteConfig;
  final List<String> createdEnvFiles;
  final List<String> createdScripts;
  final List<String> skipped;
  final ToolkitInstallResult? toolkitInstall;
  final FeatureScaffoldResult? featureScaffold;
  final StateManagementApplyResult? stateManagementApply;

  SetupResult copyWith({
    List<String>? skipped,
    ToolkitInstallResult? toolkitInstall,
  }) {
    return SetupResult(
      wroteConfig: wroteConfig,
      createdEnvFiles: createdEnvFiles,
      createdScripts: createdScripts,
      skipped: skipped ?? this.skipped,
      toolkitInstall: toolkitInstall ?? this.toolkitInstall,
      featureScaffold: featureScaffold,
      stateManagementApply: stateManagementApply,
    );
  }
}

bool setupHasRetryableFailures(SetupResult result) {
  return result.toolkitInstall?.error != null;
}

SetupResult updateToolkitInstallResult(
  SetupResult result,
  ToolkitInstallResult install,
) {
  final skipped = result.skipped
      .where((item) => !item.startsWith('toolkit install failed:'))
      .toList();
  if (install.skipped && install.detail != null) {
    skipped.add(install.detail!);
  } else if (install.error != null) {
    skipped.add('toolkit install failed: ${install.error}');
  }
  return result.copyWith(skipped: skipped, toolkitInstall: install);
}

Future<SetupResult> applySetupPlan(
  SetupPlan plan, {
  bool force = false,
  bool dryRun = false,
}) async {
  final skipped = <String>[];
  final createdEnvFiles = <String>[];
  final createdScripts = <String>[];
  var wroteConfig = false;

  final configFile = File(p.join(projectRoot(plan).path, 'release-toolkit.config.json'));
  if (configFile.existsSync() && !force) {
    skipped.add('${configFile.path} (exists; use --force to overwrite)');
  } else {
    final jsonText = const JsonEncoder.withIndent('  ').convert(plan.toConfigJson());
    if (dryRun) {
      print('Would write ${configFile.path}');
    } else {
      configFile.parent.createSync(recursive: true);
      configFile.writeAsStringSync('$jsonText\n');
      wroteConfig = true;
    }
  }

  if (plan.createEnvTemplates) {
    final template = envTemplateContent(plan.versionKeys, api: plan.api);
    for (final entry in plan.environments.entries) {
      final envFile = File(p.join(plan.projectRoot.path, entry.value));
      if (envFile.existsSync()) {
        skipped.add('${envFile.path} (exists)');
        continue;
      }
      if (dryRun) {
        print('Would create ${envFile.path}');
      } else {
        envFile.parent.createSync(recursive: true);
        envFile.writeAsStringSync(template);
        createdEnvFiles.add(envFile.path);
      }
    }
  }

  final toolkitInstall = await applyToolkitInstall(
    toolkitInstallPlanFrom(plan),
    dryRun: dryRun,
  );
  if (toolkitInstall.skipped && toolkitInstall.detail != null) {
    skipped.add(toolkitInstall.detail!);
  } else if (toolkitInstall.error != null) {
    skipped.add('toolkit install failed: ${toolkitInstall.error}');
  } else if (dryRun && toolkitInstall.detail != null) {
    print(toolkitInstall.detail);
  } else if (toolkitInstall.applied && toolkitInstall.detail != null) {
    print(toolkitInstall.detail);
  }

  final stateManagementApply = await applyStateManagementPackages(
    plan.projectRoot,
    plan.stateManagement,
    dryRun: dryRun,
  );
  if (stateManagementApply.skipped && stateManagementApply.detail != null) {
    skipped.add(stateManagementApply.detail!);
  } else if (stateManagementApply.error != null) {
    skipped.add('state management setup failed: ${stateManagementApply.error}');
  } else if (dryRun && stateManagementApply.detail != null) {
    print(stateManagementApply.detail);
  } else if (stateManagementApply.applied && stateManagementApply.detail != null) {
    print(stateManagementApply.detail);
  }

  final bootstrap = await bootstrapProjectArchitecture(
    projectRoot: plan.projectRoot,
    architecture: plan.architecture,
    environmentNames: plan.environments.keys.toList(),
    dryRun: dryRun,
  );
  if (bootstrap.createdPaths.isNotEmpty && dryRun) {
    print('Would bootstrap architecture (${bootstrap.createdPaths.length} paths)');
  }

  final apiScaffold = await scaffoldApiLayer(
    projectRoot: plan.projectRoot,
    config: plan.api,
    dryRun: dryRun,
  );
  if (apiScaffold.createdPaths.isNotEmpty && dryRun) {
    print('Would scaffold API layer (${apiScaffold.createdPaths.length} files)');
  }

  final apiPackages = await applyApiPackages(
    plan.projectRoot,
    plan.api,
    dryRun: dryRun,
  );
  for (final detail in apiPackages.details) {
    if (dryRun) {
      print(detail);
    } else if (apiPackages.applied) {
      print(detail);
    }
  }
  if (apiPackages.error != null) {
    skipped.add('API packages: ${apiPackages.error}');
  }

  if (plan.createScripts) {
    createdScripts.addAll(await rewriteProjectScripts(plan, force: force, dryRun: dryRun));
    if (!dryRun) {
      await _removeStaleToolkitScripts(plan);
    }
  }

  if (plan.createCiWorkflow) {
    final workflowPath = p.join(
      plan.projectRoot.path,
      '.github',
      'workflows',
      'flutter-release.yml',
    );
    if (dryRun) {
      print('Would write $workflowPath');
    } else {
      final config = ToolkitConfig(
        projectRoot: plan.projectRoot,
        environments: plan.environments,
        versionKeys: plan.versionKeys,
        mainDartEnvRules: plan.mainDartEnvRules,
        build: plan.build,
        defaultEnvironment: plan.defaultEnvironment,
        stateManagement: plan.stateManagement,
        architecture: plan.architecture,
        api: plan.api,
      );
      final workflowFile = File(workflowPath);
      workflowFile.parent.createSync(recursive: true);
      workflowFile.writeAsStringSync(generateGitHubActionsWorkflow(config: config));
      createdScripts.add(workflowPath);
      final fastlane = File(p.join(plan.projectRoot.path, 'fastlane', 'Fastfile'));
      if (!fastlane.existsSync()) {
        fastlane.parent.createSync(recursive: true);
        fastlane.writeAsStringSync(generateFastlaneStub());
      }
    }
  }

  if (!dryRun) {
    await writeGuardrailsSnippetIfMissing(plan.projectRoot);
    for (final entry in contractCodegenStubFiles(api: plan.api).entries) {
      final file = File(p.join(plan.projectRoot.path, entry.key));
      if (file.existsSync()) continue;
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(entry.value);
    }
  }

  FeatureScaffoldResult? featureScaffold;
  if (plan.featureToScaffold != null && plan.featureToScaffold!.isNotEmpty) {
    featureScaffold = await scaffoldFeature(
      projectRoot: plan.projectRoot,
      featureName: plan.featureToScaffold!,
      basePath: plan.featureBasePath,
      stateManagement: plan.stateManagement,
      architecture: plan.architecture,
      api: plan.api,
      dryRun: dryRun,
    );
  }

  return SetupResult(
    wroteConfig: wroteConfig,
    createdEnvFiles: createdEnvFiles,
    createdScripts: createdScripts,
    skipped: skipped,
    toolkitInstall: toolkitInstall,
    featureScaffold: featureScaffold,
    stateManagementApply: stateManagementApply,
  );
}

Directory projectRoot(SetupPlan plan) => plan.projectRoot;

Future<List<String>> rewriteProjectScripts(
  SetupPlan plan, {
  bool force = true,
  bool dryRun = false,
}) async {
  if (!plan.createScripts) {
    return [];
  }
  final written = <String>[];
  final scriptsDir = Directory(p.join(plan.projectRoot.path, 'scripts'));
  for (final entry in _scriptFilesForPlan(plan).entries) {
    final file = File(p.join(scriptsDir.path, entry.key));
    if (file.existsSync() && !force) {
      continue;
    }
    if (dryRun) {
      print('Would write ${file.path}');
      continue;
    }
    scriptsDir.createSync(recursive: true);
    file.writeAsStringSync(entry.value);
    if (Platform.isLinux || Platform.isMacOS) {
      await Process.run('chmod', ['+x', file.path]);
    }
    written.add(file.path);
  }
  return written;
}

Future<void> _removeStaleToolkitScripts(SetupPlan plan) async {
  if (plan.toolkitMode == ToolkitInstallMode.localClone) {
    return;
  }
  final locate = File(p.join(plan.projectRoot.path, 'scripts', 'rtk-locate.sh'));
  if (locate.existsSync()) {
    locate.deleteSync();
  }
}

Future<({SetupPlan plan, SetupResult result})> retryFailedSetupInteractive(
  SetupPlan plan,
  SetupResult result,
) async {
  var currentPlan = plan;
  var currentResult = result;

  while (setupHasRetryableFailures(currentResult)) {
    print('');
    print('=== Setup needs attention ===');
    if (currentResult.toolkitInstall?.error != null) {
      print('Toolkit: ${currentResult.toolkitInstall!.error}');
    }

    final choice = promptChoiceValue(
      'What would you like to do?',
      [
        'Retry toolkit setup',
        'Change toolkit path and retry',
        'Change toolkit install mode and retry',
        'Continue without fixing',
      ],
      defaultIndex: 0,
    );

    if (choice == 'Continue without fixing') {
      break;
    }

    if (choice == 'Change toolkit path and retry') {
      final detected = detectRunningToolkitRoot();
      final defaultPath = currentPlan.localToolkitPath ??
          (detected != null
              ? posixRelativePath(currentPlan.projectRoot, detected)
              : '../flutter-project-setup-toolkit');
      final newPath = promptLine(
        'Path to flutter-project-setup-toolkit (relative to project)',
        defaultValue: defaultPath,
      );
      currentPlan = currentPlan.copyWith(
        toolkitMode: ToolkitInstallMode.localClone,
        localToolkitPath: newPath.isEmpty ? defaultPath : newPath,
        clearToolkitInstallPath: true,
      );
      await rewriteProjectScripts(currentPlan);
      await _removeStaleToolkitScripts(currentPlan);
    } else if (choice == 'Change toolkit install mode and retry') {
      currentPlan = _editToolkitInstallMode(currentPlan);
      await rewriteProjectScripts(currentPlan);
      await _removeStaleToolkitScripts(currentPlan);
    }

    final install = await applyToolkitInstall(toolkitInstallPlanFrom(currentPlan));
    currentResult = updateToolkitInstallResult(currentResult, install);
    if (install.applied) {
      print('');
      print('Toolkit setup succeeded: ${install.detail}');
    } else if (install.skipped &&
        currentPlan.toolkitMode == ToolkitInstallMode.devDependency) {
      print('');
      print('Toolkit setup OK: ${install.detail}');
    } else if (install.error != null) {
      print('');
      print('Toolkit setup still failed: ${install.error}');
    }
  }

  return (plan: currentPlan, result: currentResult);
}

Map<String, String> setupScriptContentsForPlan(SetupPlan plan) =>
    _scriptFilesForPlan(plan);

Map<String, String> _scriptFilesForPlan(SetupPlan plan) {
  final files = <String, String>{};
  if (plan.toolkitMode == ToolkitInstallMode.localClone) {
    files['rtk-locate.sh'] = _rtkLocateScript(plan.localToolkitPath ?? '../flutter-project-setup-toolkit');
  }
  final runner = _commandRunner(plan);
  files['classify-version-bump.sh'] = _wrapperScript(
    plan,
    runner: runner,
    executable: 'classify_version_bump',
    description: 'Classify semver bump and optionally update env version keys.',
  );
  files['build-android.sh'] = _wrapperScript(
    plan,
    runner: runner,
    executable: 'build_android',
    description: 'Release Android APK or AAB build.',
  );
  files['build-ios-ipa.sh'] = _wrapperScript(
    plan,
    runner: runner,
    executable: 'build_ios_ipa',
    description: 'Release iOS IPA build (macOS only).',
  );
  files['build-distribution.sh'] = _wrapperScript(
    plan,
    runner: runner,
    executable: 'build_distribution',
    description: 'Open Distribution Studio GUI for TestFlight IPA & beta APK builds.',
  );
  files['toolkit-studio.sh'] = _wrapperScript(
    plan,
    runner: runner,
    executable: 'toolkit_studio',
    description: 'Open Flutter Project Setup Toolkit — full GUI for setup, build, and features.',
  );
  files['setup-studio.sh'] = _wrapperScript(
    plan,
    runner: runner,
    executable: 'setup_studio',
    description: 'Open Setup Studio GUI for interactive project configuration.',
  );
  files['make-feature.sh'] = _wrapperScript(
    plan,
    runner: runner,
    executable: 'make_feature',
    description: 'Scaffold a clean-architecture feature folder.',
  );
  return files;
}

String _commandRunner(SetupPlan plan) {
  switch (plan.toolkitMode) {
    case ToolkitInstallMode.globalCli:
      return 'global';
    case ToolkitInstallMode.localClone:
      return 'local';
    case ToolkitInstallMode.devDependency:
      return 'dev_dependency';
  }
}

String _scriptUsageHelp(String executable) {
  return switch (executable) {
    'classify_version_bump' => '''
# Examples:
#   ./scripts/classify-version-bump.sh --env prod --suggest --verbose
#   ./scripts/classify-version-bump.sh --env prod --apply-env --dry-run
#   ./scripts/classify-version-bump.sh --env-file .env/prod.env --verbose
#
# Common options: --env, --env-file, --suggest, --apply-env, --dry-run, --yes, --json
# Help: dart run flutter_project_setup_toolkit:classify_version_bump --help''',
    'build_android' => '''
# Examples:
#   ./scripts/build-android.sh --env prod
#   ./scripts/build-android.sh --env prod --aab
#   ./scripts/build-android.sh --env-file .env/production.env --flavor staging
#
# Env: SKIP_CONFIRM=true, BUILD_FORMAT=aab, ANDROID_FLAVOR=name
# Help: dart run flutter_project_setup_toolkit:build_android --help''',
    'build_ios_ipa' => '''
# Examples (macOS only):
#   ./scripts/build-ios-ipa.sh --env prod
#   ./scripts/build-ios-ipa.sh --env prod --scheme Runner --no-organizer
#
# Env: SKIP_CONFIRM=true, IOS_SCHEME=Runner, OPEN_ORGANIZER=false
# Help: dart run flutter_project_setup_toolkit:build_ios_ipa --help''',
    'build_distribution' => '''
# Examples:
#   ./scripts/build-distribution.sh --project .
#   ./scripts/build-distribution.sh --studio
#
# Opens Distribution Studio GUI (APK, AAB, IPA, Git remote builds).
# Help: dart run flutter_project_setup_toolkit:build_distribution --help''',
    'toolkit_studio' => '''
# Examples:
#   ./scripts/toolkit-studio.sh
#   ./scripts/toolkit-studio.sh --view quick-test
#   ./scripts/toolkit-studio.sh --project . --view setup
#
# macOS: desktop app by default; pass --browser for web UI.
# Help: dart run flutter_project_setup_toolkit:toolkit_studio --help''',
    'setup_studio' => '''
# Examples:
#   ./scripts/setup-studio.sh --project .
#
# Opens Setup Studio only (legacy; prefer toolkit-studio.sh hub).
# Help: dart run flutter_project_setup_toolkit:setup_studio --help''',
    'make_feature' => '''
# Examples:
#   ./scripts/make-feature.sh authentication
#   ./scripts/make-feature.sh settings lib/modules
#   ./scripts/make-feature.sh --feature billing --dry-run
#
# Positional: feature name, optional base path (default: lib/features).
# Help: dart run flutter_project_setup_toolkit:make_feature --help''',
    _ => '''
# Help: dart run flutter_project_setup_toolkit:$executable --help''',
  };
}

String _wrapperScript(
  SetupPlan plan, {
  required String runner,
  required String executable,
  required String description,
}) {
  final shellName = executable.replaceAll('_', '-');
  final usageHelp = _scriptUsageHelp(executable);
  final locateBlock = runner == 'local'
      ? '''
# shellcheck source=rtk-locate.sh
source "\$(dirname "\${BASH_SOURCE[0]}")/rtk-locate.sh"
'''
      : '';
  final runBlock = switch (runner) {
    'global' => 'exec $executable --project "\$APP_ROOT" "\$@"',
    'local' => '''
cd "\$RTK_ROOT"
exec dart run $toolkitPackageName:$executable --project "\$APP_ROOT" "\$@"
''',
    _ => '''
cd "\$APP_ROOT"
exec dart run $toolkitPackageName:$executable --project "\$APP_ROOT" "\$@"
''',
  };
  return '''
#!/usr/bin/env bash
#
# Flutter Project Setup Toolkit — $shellName
#
# $description
#
# Run from: your Flutter app root (this file is in scripts/).
#   cd /path/to/your_flutter_app && ./scripts/$shellName.sh [OPTIONS]
#
# The script sets --project to the app root automatically.
# Pass any CLI flags after the script name (see examples below).
$usageHelp
#
set -euo pipefail
APP_ROOT="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")/.." && pwd)"
$locateBlock$runBlock
''';
}

String _rtkLocateScript(String toolkitRelPath) {
  return '''
#!/usr/bin/env bash
#
# Locate flutter-project-setup-toolkit checkout for local-clone install mode.
#
# Sourced by other scripts/ wrappers — do not run directly.
# Sets RTK_ROOT to the toolkit directory.
#
# Override path:
#   export FLUTTER_PROJECT_SETUP_TOOLKIT=/path/to/flutter-project-setup-toolkit
#
set -euo pipefail
APP_ROOT="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")/.." && pwd)"
RTK_DEFAULT="\$(cd "\$APP_ROOT/$toolkitRelPath" && pwd)"
export FLUTTER_PROJECT_SETUP_TOOLKIT="\${FLUTTER_PROJECT_SETUP_TOOLKIT:-\${FLUTTER_RELEASE_TOOLKIT:-\$RTK_DEFAULT}}"
# shellcheck source=/dev/null
source "\$FLUTTER_PROJECT_SETUP_TOOLKIT/lib/sh/locate-toolkit.sh"
_rtk_locate_toolkit "\$APP_ROOT" || exit 1
''';
}

void printSetupSummary(SetupPlan plan, SetupResult result) {
  print('');
  print('=== Setup complete ===');
  print('Default environment: ${plan.defaultEnvironment}');
  for (final entry in plan.environments.entries) {
    final marker = entry.key == plan.defaultEnvironment ? ' (default)' : '';
    print('  ${entry.key}$marker -> ${entry.value}');
  }
  if (result.wroteConfig) {
    print('Wrote release-toolkit.config.json');
  }
  if (result.createdEnvFiles.isNotEmpty) {
    print('Created env templates:');
    for (final path in result.createdEnvFiles) {
      print('  $path');
    }
  }
  if (result.createdScripts.isNotEmpty) {
    print('Created scripts:');
    for (final path in result.createdScripts) {
      print('  $path');
    }
  }
  if (result.featureScaffold != null) {
    if (result.featureScaffold!.dryRun) {
      print('Feature scaffold (dry-run): ${result.featureScaffold!.rootPath}');
    } else {
      printFeatureScaffoldSummary(result.featureScaffold!);
    }
  }
  if (result.toolkitInstall?.applied == true && result.toolkitInstall?.detail != null) {
    print('Toolkit: ${result.toolkitInstall!.detail}');
  }
  if (result.stateManagementApply?.applied == true &&
      result.stateManagementApply?.detail != null) {
    print('State management: ${result.stateManagementApply!.detail}');
  }
  if (result.skipped.isNotEmpty) {
    print('Skipped:');
    for (final item in result.skipped) {
      print('  $item');
    }
  }
  print('');
  print('Next steps:');
  if (!_toolkitInstallComplete(plan, result)) {
    _printToolkitInstallHint(plan);
  }
  print('  1. Fill in secrets in your env files (API keys, etc.)');
  if (result.featureScaffold != null && !result.featureScaffold!.dryRun) {
    print('  2. Implement ${result.featureScaffold!.rootPath} (started for you)');
    print('  3. Run: ./scripts/classify-version-bump.sh --verbose');
    print('  4. Build: ./scripts/build-android.sh --env ${plan.defaultEnvironment}');
    print('  5. Flutter Project Setup Toolkit: ./scripts/toolkit-studio.sh');
  } else {
    print('  2. Scaffold features: ./scripts/make-feature.sh <name>  (or dart run $toolkitPackageName:make_feature)');
    print('  3. Run: ./scripts/classify-version-bump.sh --verbose');
    print('  4. Build: ./scripts/build-android.sh --env ${plan.defaultEnvironment}');
    print('  5. Flutter Project Setup Toolkit: ./scripts/toolkit-studio.sh');
  }
}

bool _toolkitInstallComplete(SetupPlan plan, SetupResult result) {
  final install = result.toolkitInstall;
  if (install == null) {
    return false;
  }
  if (install.applied) {
    return true;
  }
  if (install.skipped && plan.toolkitMode == ToolkitInstallMode.devDependency) {
    return true;
  }
  return plan.toolkitMode == ToolkitInstallMode.localClone && install.error == null;
}

void _printToolkitInstallHint(SetupPlan plan) {
  switch (plan.toolkitMode) {
    case ToolkitInstallMode.devDependency:
      print('  0. Add dev dependency (pick one):');
      print('       dart pub add --dev $toolkitPackageName');
      print('       # or path: $toolkitPackageName: { path: ../flutter-project-setup-toolkit }');
    case ToolkitInstallMode.localClone:
      print('  0. Ensure flutter-project-setup-toolkit is at: ${plan.localToolkitPath}');
    case ToolkitInstallMode.globalCli:
      print('  0. dart pub global activate $toolkitPackageName');
  }
}

void printSetupPlanSummary(SetupPlan plan) {
  print('');
  print('=== Setup summary ===');
  print('Project: ${plan.projectRoot.path}');
  print('Default environment: ${plan.defaultEnvironment}');
  print('Environments:');
  for (final entry in plan.environments.entries) {
    final marker = entry.key == plan.defaultEnvironment ? ' (default)' : '';
    final warning = entry.value.endsWith('.env') ? '' : '  [!] unusual path';
    print('  ${entry.key}$marker -> ${entry.value}$warning');
  }
  print('Version keys:');
  for (final entry in plan.versionKeys.entries) {
    print('  ${entry.key}: ${entry.value}');
  }
  final build = plan.build;
  print('Build flavors:');
  print('  iOS scheme: ${build.iosScheme}');
  print('  iOS flavor: ${build.iosFlavor ?? '(none)'}');
  print('  Android: ${build.androidFlavor ?? '(none)'}');
  print('Toolkit mode: ${_toolkitModeLabel(plan.toolkitMode)}');
  if (plan.toolkitMode == ToolkitInstallMode.localClone) {
    print('  Toolkit path: ${plan.localToolkitPath ?? '../flutter-project-setup-toolkit'}');
  }
  print('Create env templates: ${plan.createEnvTemplates ? 'yes' : 'no'}');
  print('Create scripts/: ${plan.createScripts ? 'yes' : 'no'}');
  print('State management: ${stateManagementLabel(plan.stateManagement)}');
  print('Architecture: ${plan.architecture.preset.label}');
  print('API: ${plan.api.protocol.label}');
  if (plan.featureToScaffold != null) {
    print('Feature scaffold: ${plan.featureToScaffold} -> ${plan.featureBasePath}/');
  } else {
    print('Feature scaffold: (none)');
  }
  if (plan.mainDartEnvRules.isNotEmpty) {
    print('main.dart env rules: ${plan.mainDartEnvRules.length}');
  }
}

String _toolkitModeLabel(ToolkitInstallMode mode) {
  return switch (mode) {
    ToolkitInstallMode.devDependency => 'dev_dependency in pubspec.yaml',
    ToolkitInstallMode.localClone => 'local clone',
    ToolkitInstallMode.globalCli => 'pub global activate',
  };
}

Future<SetupPlan?> reviewSetupPlanInteractive(SetupPlan plan) async {
  var current = plan;
  while (true) {
    printSetupPlanSummary(current);
    final choice = promptChoiceValue(
      'What would you like to do?',
      [
        'Apply this setup',
        'Change default environment',
        'Change an env file path',
        'Change version key names',
        'Change build flavors',
        'Change toolkit install mode',
        'Change state management',
        'Change feature scaffold',
        'Toggle env templates / scripts',
        'Cancel setup',
      ],
      defaultIndex: 0,
    );

    switch (choice) {
      case 'Apply this setup':
        return current;
      case 'Change default environment':
        current = _editDefaultEnvironment(current);
      case 'Change an env file path':
        current = _editEnvFilePath(current);
      case 'Change version key names':
        current = _editVersionKeys(current);
      case 'Change build flavors':
        current = _editBuildFlavors(current);
      case 'Change toolkit install mode':
        current = _editToolkitInstallMode(current);
      case 'Change state management':
        current = _editStateManagement(current);
      case 'Change feature scaffold':
        current = _editFeatureScaffold(current);
      case 'Toggle env templates / scripts':
        current = _editScaffoldingToggles(current);
      case 'Cancel setup':
        return null;
    }
  }
}

SetupPlan _editDefaultEnvironment(SetupPlan plan) {
  final names = plan.environments.keys.toList();
  final selected = promptChoiceValue(
    'Which environment will you work on most often?',
    names,
    defaultIndex: names.indexOf(plan.defaultEnvironment).clamp(0, names.length - 1),
  );
  return plan.copyWith(defaultEnvironment: selected);
}

SetupPlan _editEnvFilePath(SetupPlan plan) {
  final names = plan.environments.keys.toList();
  final envName = promptChoiceValue('Which environment path?', names);
  final updated = Map<String, String>.from(plan.environments);
  final path = promptLine(
    'Path for $envName',
    defaultValue: updated[envName],
  );
  updated[envName] = path.isEmpty ? updated[envName]! : path;
  if (!updated[envName]!.endsWith('.env')) {
    print('  Note: env paths usually end with .env (e.g. .env/production.env)');
  }
  return plan.copyWith(environments: updated);
}

SetupPlan _editVersionKeys(SetupPlan plan) {
  final keys = Map<String, String>.from(plan.versionKeys);
  if (promptYesNo('Use default version key names (APP_VERSION_NAME, etc.)?', defaultYes: true)) {
    return plan.copyWith(versionKeys: Map<String, String>.from(defaultVersionKeys));
  }
  keys['android_name'] =
      promptLine('Android marketing version key', defaultValue: keys['android_name']);
  keys['android_code'] =
      promptLine('Android version code key', defaultValue: keys['android_code']);
  keys['ios_marketing'] =
      promptLine('iOS marketing version key', defaultValue: keys['ios_marketing']);
  keys['ios_build'] =
      promptLine('iOS build number key', defaultValue: keys['ios_build']);
  return plan.copyWith(versionKeys: keys);
}

SetupPlan _editBuildFlavors(SetupPlan plan) {
  String? iosFlavor;
  String? androidFlavor;
  var iosScheme = plan.build.iosScheme;
  final iosDetection = detectIosBuildSettings(plan.projectRoot);
  if (iosDetection != null && iosDetection.appSchemes.isNotEmpty) {
    print('');
    print('Detected iOS Xcode schemes: ${iosDetection.appSchemes.join(', ')}');
    if (iosDetection.appSchemes.length == 1) {
      iosScheme = iosDetection.appSchemes.first;
    } else if (promptYesNo(
      'Change iOS Xcode scheme? (current: $iosScheme)',
      defaultYes: !iosDetection.appSchemes
          .any((s) => s.toLowerCase() == iosScheme.toLowerCase()),
    )) {
      iosScheme = promptChoiceValue(
        'Which Xcode scheme should iOS builds use?',
        iosDetection.appSchemes,
        defaultIndex: iosDetection.appSchemes
            .indexWhere((s) => s.toLowerCase() == iosScheme.toLowerCase())
            .clamp(0, iosDetection.appSchemes.length - 1),
      );
    }
  }
  if (promptYesNo('Does your app use iOS build flavors?', defaultYes: plan.build.iosFlavor != null)) {
    iosFlavor = promptLine('iOS flavor name', defaultValue: plan.build.iosFlavor ?? '');
    if (iosFlavor.isEmpty) iosFlavor = null;
  }
  if (promptYesNo(
    'Does your app use Android product flavors?',
    defaultYes: plan.build.androidFlavor != null,
  )) {
    androidFlavor = promptLine('Android flavor name', defaultValue: plan.build.androidFlavor ?? '');
    if (androidFlavor.isEmpty) androidFlavor = null;
  }
  return plan.copyWith(
    build: BuildConfig(
      androidFlavor: androidFlavor,
      iosFlavor: iosFlavor,
      iosScheme: iosScheme,
      openOrganizer: plan.build.openOrganizer,
    ),
  );
}

SetupPlan _editToolkitInstallMode(SetupPlan plan) {
  final mode = _toolkitModeFromLabel(
    promptChoiceValue(
      'How will you run the toolkit?',
      [
        'dev_dependency in pubspec.yaml (recommended)',
        'local clone (path to flutter-project-setup-toolkit)',
        'pub global activate',
      ],
      defaultIndex: switch (plan.toolkitMode) {
        ToolkitInstallMode.localClone => 1,
        ToolkitInstallMode.globalCli => 2,
        _ => 0,
      },
    ),
  );

  String? localToolkitPath;
  String? toolkitInstallPath;
  switch (mode) {
    case ToolkitInstallMode.localClone:
      localToolkitPath = promptLine(
        'Path to flutter-project-setup-toolkit',
        defaultValue: plan.localToolkitPath ?? '../flutter-project-setup-toolkit',
      );
    case ToolkitInstallMode.devDependency:
      toolkitInstallPath = resolveToolkitInstallPath(
        ToolkitInstallPlan(
          projectRoot: plan.projectRoot,
          mode: mode,
          toolkitInstallPath: plan.toolkitInstallPath,
        ),
      );
    case ToolkitInstallMode.globalCli:
      break;
  }

  return plan.copyWith(
    toolkitMode: mode,
    localToolkitPath: localToolkitPath,
    toolkitInstallPath: toolkitInstallPath,
    clearLocalToolkitPath: mode != ToolkitInstallMode.localClone,
    clearToolkitInstallPath: mode != ToolkitInstallMode.devDependency,
  );
}

SetupPlan _editStateManagement(SetupPlan plan) {
  return plan.copyWith(
    stateManagement: promptStateManagement(defaultChoice: plan.stateManagement),
  );
}

SetupPlan _editFeatureScaffold(SetupPlan plan) {
  if (!promptYesNo('Scaffold a feature to start working on?', defaultYes: plan.featureToScaffold != null)) {
    return plan.copyWith(clearFeatureToScaffold: true);
  }
  var featureName = promptLine(
    'What feature do you want to work on?',
    defaultValue: plan.featureToScaffold ?? '',
  );
  while (featureName.isEmpty) {
    featureName = promptLine('Feature name is required');
  }
  var featureBasePath = plan.featureBasePath;
  if (!promptYesNo('Use base path lib/features/?', defaultYes: featureBasePath == 'lib/features')) {
    featureBasePath = promptLine('Base path', defaultValue: featureBasePath);
  }
  return plan.copyWith(
    featureToScaffold: featureName,
    featureBasePath: featureBasePath,
  );
}

SetupPlan _editScaffoldingToggles(SetupPlan plan) {
  final createEnvTemplates = promptYesNo(
    'Create env file templates with version keys?',
    defaultYes: plan.createEnvTemplates,
  );
  final createScripts = promptYesNo(
    'Create scripts/ wrapper scripts in your app?',
    defaultYes: plan.createScripts,
  );
  return plan.copyWith(
    createEnvTemplates: createEnvTemplates,
    createScripts: createScripts,
  );
}
