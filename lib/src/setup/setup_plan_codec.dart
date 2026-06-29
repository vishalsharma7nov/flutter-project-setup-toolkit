import 'dart:io';

import 'package:path/path.dart' as p;

import '../api/api_config.dart';
import '../architecture/architecture_compatibility.dart';
import '../architecture/architecture_config.dart';
import '../architecture/architecture_compatibility.dart';
import '../architecture/architecture_preset.dart';
import '../api/api_protocol.dart';
import '../config.dart';
import '../models.dart';
import '../setup_wizard.dart';
import '../toolkit_install.dart';
import 'setup_arch_api_codec.dart';

Map<String, dynamic> detectSetupProject(Directory projectRoot) {
  validateFlutterProject(projectRoot);
  final configFile = File(p.join(projectRoot.path, 'release-toolkit.config.json'));
  final rules = detectMainDartEnvRules(projectRoot);
  final detected = detectRunningToolkitRoot();
  final suggestedPath = detected != null
      ? posixRelativePath(projectRoot, detected)
      : '../flutter-project-setup-toolkit';

  return {
    'project_path': projectRoot.path,
    'has_existing_config': configFile.existsSync(),
    'main_dart_rules': rules
        .map((rule) => {'match': rule.match, 'environment': rule.environment})
        .toList(),
    'suggested_local_toolkit_path': suggestedPath,
    'default_version_keys': defaultVersionKeys,
    'state_management_options': StateManagement.values.map((v) => v.name).toList(),
    'architecture_options': architecturePresetOptions(),
    'architecture_option_groups': architecturePresetOptionGroups(),
    'api_protocol_options': ApiProtocol.values.map((p) => p.id).toList(),
    'default_architecture': ArchitectureConfig.defaults().preset.id,
    'default_api_protocol': ApiConfig.defaults().protocol.id,
    if (configFile.existsSync()) ..._existingConfigDetect(projectRoot),
    'env_path_presets': {
      'dev-prod': _envPathsForPreset(EnvPreset.devProd, EnvDirectoryStyle.dotEnv),
      'dev-staging-prod':
          _envPathsForPreset(EnvPreset.devStagingProd, EnvDirectoryStyle.dotEnv),
      'dev-prod-secrets':
          _envPathsForPreset(EnvPreset.devProd, EnvDirectoryStyle.dotSecrets),
    },
  };
}

Map<String, String> _envPathsForPreset(
  EnvPreset preset,
  EnvDirectoryStyle style,
) {
  return defaultEnvPaths(preset.names, style, 'config/env');
}

Map<String, dynamic> _existingConfigDetect(Directory projectRoot) {
  final config = loadConfig(projectRoot);
  return {
    'architecture': config.architecture.preset.id,
    'api_protocol': config.api.protocol.id,
    'feature_base_path': config.architecture.featureBasePath,
    'state_management': config.stateManagement.name,
    if (config.architecture.customTemplatePath != null)
      'custom_template_path': config.architecture.customTemplatePath,
    if (config.api.externalSdk?.isConfigured == true)
      'external_sdk': config.api.externalSdk!.toJson(),
  };
}

Map<String, String> computeEnvPathsFromGui(Map<String, dynamic> body) {
  final preset = body['env_preset'] as String? ?? 'dev-prod';
  final customNames = _parseEnvNames(body['custom_env_names'] as String? ?? 'dev,prod');
  final envPreset = switch (preset) {
    'dev-staging-prod' => EnvPreset.devStagingProd,
    'custom' => EnvPreset.custom,
    _ => EnvPreset.devProd,
  };
  final envNames = envPreset == EnvPreset.custom ? customNames : envPreset.names;
  final dirStyle = _dirStyleFromGui(body['env_dir_style'] as String?);
  final customPrefix = body['env_custom_prefix'] as String? ?? 'config/env';
  return defaultEnvPaths(envNames, dirStyle, customPrefix);
}

SetupPlan setupPlanFromGuiMap(Directory projectRoot, Map<String, dynamic> body) {
  validateFlutterProject(projectRoot);

  final preset = body['env_preset'] as String? ?? 'dev-prod';
  final customNames = _parseEnvNames(body['custom_env_names'] as String? ?? 'dev,prod');
  final envPreset = switch (preset) {
    'dev-staging-prod' => EnvPreset.devStagingProd,
    'custom' => EnvPreset.custom,
    _ => EnvPreset.devProd,
  };
  final envNames = envPreset == EnvPreset.custom ? customNames : envPreset.names;
  if (envNames.isEmpty) {
    throw ArgumentError('At least one environment name is required');
  }

  final dirStyle = _dirStyleFromGui(body['env_dir_style'] as String?);
  final customPrefix = body['env_custom_prefix'] as String? ?? 'config/env';

  Map<String, String> environments;
  if (body['environments'] is Map) {
    environments = (body['environments'] as Map).map(
      (key, value) => MapEntry('$key', '$value'),
    );
  } else {
    environments = defaultEnvPaths(envNames, dirStyle, customPrefix);
  }

  for (final name in envNames) {
    environments.putIfAbsent(
      name,
      () => defaultEnvPaths([name], dirStyle, customPrefix)[name]!,
    );
  }

  final defaultEnvironment = body['default_environment'] as String? ?? envNames.first;
  if (!environments.containsKey(defaultEnvironment)) {
    throw ArgumentError("default environment '$defaultEnvironment' is not configured");
  }

  final versionKeys = body['use_default_version_keys'] == false && body['version_keys'] is Map
      ? (body['version_keys'] as Map).map(
          (key, value) => MapEntry('$key', '$value'),
        )
      : Map<String, String>.from(defaultVersionKeys);

  final includeRules = body['include_main_dart_rules'] as bool? ?? true;
  final detectedRules = detectMainDartEnvRules(projectRoot);
  final mainDartRules = includeRules
      ? (body['main_dart_rules'] is List && (body['main_dart_rules'] as List).isNotEmpty
          ? (body['main_dart_rules'] as List)
              .map(
                (item) => MainDartEnvRule(
                  match: (item as Map)['match'] as String,
                  environment: item['environment'] as String,
                ),
              )
              .toList()
          : detectedRules)
      : <MainDartEnvRule>[];

  final toolkitMode = _toolkitModeFromGui(body['toolkit_mode'] as String?);
  String? localToolkitPath = body['local_toolkit_path'] as String?;
  String? toolkitInstallPath;

  switch (toolkitMode) {
    case ToolkitInstallMode.localClone:
      localToolkitPath ??= '../flutter-project-setup-toolkit';
    case ToolkitInstallMode.devDependency:
      toolkitInstallPath = body['toolkit_install_path'] as String? ??
          resolveToolkitInstallPath(
            ToolkitInstallPlan(
              projectRoot: projectRoot,
              mode: ToolkitInstallMode.devDependency,
            ),
          );
    case ToolkitInstallMode.globalCli:
      break;
  }

  final iosFlavor = _optionalString(body['ios_flavor']);
  final androidFlavor = _optionalString(body['android_flavor']);
  final featureName = _optionalString(body['feature_to_scaffold']);
  final featureBasePath =
      body['feature_base_path'] as String? ?? 'lib/features';

  final architecture = architectureConfigFromBody(body);
  final api = apiConfigFromBody(body);

  return buildSetupPlanFromAnswers(
    projectRoot: projectRoot,
    envNames: envNames,
    environments: environments,
    defaultEnvironment: defaultEnvironment,
    versionKeys: versionKeys,
    build: BuildConfig(
      androidFlavor: androidFlavor,
      iosFlavor: iosFlavor,
    ),
    mainDartEnvRules: mainDartRules,
    toolkitMode: toolkitMode,
    createEnvTemplates: body['create_env_templates'] as bool? ?? true,
    createScripts: body['create_scripts'] as bool? ?? true,
    localToolkitPath: localToolkitPath,
    toolkitInstallPath: toolkitInstallPath,
    featureToScaffold: featureName,
    featureBasePath: featureBasePath,
    stateManagement:
        StateManagement.parse(body['state_management'] as String?) ??
            StateManagement.none,
    architecture: architecture,
    api: api,
  );
}

Map<String, dynamic> previewSetupPlan(SetupPlan plan) {
  final projectPath = plan.projectRoot.path;
  final configFile = p.join(projectPath, 'release-toolkit.config.json');
  final configExists = File(configFile).existsSync();

  final envFiles = <Map<String, String>>[];
  if (plan.createEnvTemplates) {
    for (final entry in plan.environments.entries) {
      final fullPath = p.join(projectPath, entry.value);
      envFiles.add({
        'env': entry.key,
        'path': entry.value,
        'action': File(fullPath).existsSync() ? 'skip' : 'create',
      });
    }
  }

  final scripts = plan.createScripts
      ? setupScriptContentsForPlan(plan).keys.map((name) => 'scripts/$name').toList()
      : <String>[];

  final compatibility = architectureCompatibilityWarning(
    preset: plan.architecture.preset,
    stateManagement: plan.stateManagement,
  );

  return {
    'project_path': projectPath,
    'default_environment': plan.defaultEnvironment,
    'environments': plan.environments,
    'version_keys': plan.versionKeys,
    'state_management': plan.stateManagement.name,
    'toolkit_mode': plan.toolkitMode.name,
    'local_toolkit_path': plan.localToolkitPath,
    'create_env_templates': plan.createEnvTemplates,
    'create_scripts': plan.createScripts,
    'feature_to_scaffold': plan.featureToScaffold,
    'feature_base_path': plan.featureBasePath,
    'architecture': plan.architecture.toJson(),
    'api': plan.api.toJson(),
    'build': {
      'android_flavor': plan.build.androidFlavor,
      'ios_flavor': plan.build.iosFlavor,
    },
    'main_dart_env_rules': plan.mainDartEnvRules
        .map((rule) => {'match': rule.match, 'environment': rule.environment})
        .toList(),
    'config': {
      'path': 'release-toolkit.config.json',
      'action': configExists ? 'skip_without_force' : 'create',
      'preview': plan.toConfigJson(),
    },
    'env_files': envFiles,
    'scripts': scripts,
    if (compatibility != null) 'compatibility_warning': compatibility.message,
  };
}

Map<String, dynamic> setupResultToJson(SetupPlan plan, SetupResult result) {
  return {
    'wrote_config': result.wroteConfig,
    'created_env_files': result.createdEnvFiles,
    'created_scripts': result.createdScripts,
    'skipped': result.skipped,
    'toolkit_install': {
      'applied': result.toolkitInstall?.applied ?? false,
      'detail': result.toolkitInstall?.detail,
      'error': result.toolkitInstall?.error,
    },
    'state_management': {
      'applied': result.stateManagementApply?.applied ?? false,
      'detail': result.stateManagementApply?.detail,
      'error': result.stateManagementApply?.error,
    },
    'feature_scaffold': result.featureScaffold == null
        ? null
        : {
            'root_path': result.featureScaffold!.rootPath,
            'dry_run': result.featureScaffold!.dryRun,
          },
    'default_environment': plan.defaultEnvironment,
    'next_steps': [
      'Fill in secrets in your env files',
      if (result.featureScaffold != null && !result.featureScaffold!.dryRun)
        'Implement ${result.featureScaffold!.rootPath}'
      else
        'Scaffold features with ./scripts/make-feature.sh',
      './scripts/classify-version-bump.sh --verbose',
      './scripts/build-android.sh --env ${plan.defaultEnvironment}',
      './scripts/build-distribution.sh',
    ],
  };
}

List<String> _parseEnvNames(String raw) {
  return raw
      .split(',')
      .map((name) => name.trim().toLowerCase())
      .where((name) => name.isNotEmpty)
      .toList();
}

EnvDirectoryStyle _dirStyleFromGui(String? value) {
  return switch (value) {
    'dotSecrets' => EnvDirectoryStyle.dotSecrets,
    'custom' => EnvDirectoryStyle.custom,
    _ => EnvDirectoryStyle.dotEnv,
  };
}

ToolkitInstallMode _toolkitModeFromGui(String? value) {
  return switch (value) {
    'localClone' => ToolkitInstallMode.localClone,
    'globalCli' => ToolkitInstallMode.globalCli,
    _ => ToolkitInstallMode.devDependency,
  };
}

String? _optionalString(Object? value) {
  if (value == null) return null;
  final text = '$value'.trim();
  return text.isEmpty ? null : text;
}
