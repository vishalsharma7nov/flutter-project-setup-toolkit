import 'dart:io';

import '../api/api_config.dart';
import '../api/api_protocol.dart';
import '../architecture/architecture_core_modules.dart';
import '../architecture/architecture_config.dart';
import '../architecture/architecture_preset.dart';
import '../config_file.dart';

ArchitectureConfig architectureConfigFromBody(Map<String, dynamic> body) {
  final presetId = body['architecture_preset'] as String? ??
      (body['architecture'] is Map
          ? (body['architecture'] as Map)['preset'] as String?
          : null);
  final preset =
      ArchitecturePreset.parse(presetId) ?? ArchitecturePreset.defaultPreset;

  if (body['architecture'] is Map<String, dynamic>) {
    return ArchitectureConfig.fromJson(
      body['architecture'] as Map<String, dynamic>,
    );
  }

  final basePath = body['feature_base_path'] as String? ??
      preset.defaultFeatureBasePath;

  return ArchitectureConfig(
    preset: preset,
    featureBasePath: basePath,
    customTemplatePath: body['custom_template_path'] as String?,
    customTemplate: body['custom_template'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(
            body['custom_template'] as Map<String, dynamic>,
          )
        : null,
    coreModules: ArchitectureCoreModulesConfig(
      errors: body['core_modules_errors'] as bool? ?? false,
      logging: body['core_modules_logging'] as bool? ?? false,
      theme: body['core_modules_theme'] as bool? ?? false,
      connectivity: body['core_modules_connectivity'] as bool? ?? false,
    ),
    bootstrap: ArchitectureBootstrapConfig(
      melos: preset == ArchitecturePreset.microFeature,
      flavorMains: body['bootstrap_flavor_mains'] as bool? ?? false,
      scaffoldTestMirror: body['bootstrap_scaffold_test_mirror'] as bool? ?? false,
    ),
  );
}

ApiConfig apiConfigFromBody(Map<String, dynamic> body) {
  final protocolId = body['api_protocol'] as String? ??
      (body['api'] is Map
          ? (body['api'] as Map)['protocol'] as String?
          : null);

  if (body['api'] is Map<String, dynamic>) {
    return ApiConfig.fromJson(body['api'] as Map<String, dynamic>);
  }

  var api = ApiConfig(
    protocol: ApiProtocol.parse(protocolId) ?? ApiProtocol.rest,
  );

  if (body['external_sdk'] is Map<String, dynamic>) {
    final sdkJson = Map<String, dynamic>.from(
      body['external_sdk'] as Map<String, dynamic>,
    );
    if (!sdkJson.containsKey('package_name')) {
      sdkJson['package_name'] = 'external_sdk';
    }
    api = ApiConfig(
      protocol: ApiProtocol.externalSdk,
      clientSource: ApiClientSource.externalSdk,
      externalSdk: ExternalSdkConfig.fromJson(sdkJson),
    );
  }

  return api;
}

/// Optional per-request overrides for feature scaffold APIs.
class FeatureScaffoldOverrides {
  const FeatureScaffoldOverrides({
    this.architecture,
    this.api,
  });

  factory FeatureScaffoldOverrides.fromBody(Map<String, dynamic> body) {
    ArchitectureConfig? architecture;
    ApiConfig? api;

    if (body.containsKey('architecture_preset') ||
        body.containsKey('architecture') ||
        body.containsKey('feature_base_path') ||
        body.containsKey('custom_template_path') ||
        body.containsKey('custom_template')) {
      architecture = architectureConfigFromBody(body);
    }
    if (body.containsKey('api_protocol') ||
        body.containsKey('api') ||
        body.containsKey('external_sdk')) {
      api = apiConfigFromBody(body);
    }

    return FeatureScaffoldOverrides(architecture: architecture, api: api);
  }

  final ArchitectureConfig? architecture;
  final ApiConfig? api;
}

/// Persist architecture/API overrides from Feature Studio to project config.
Map<String, dynamic> saveArchitectureApiDefaults({
  required Directory projectRoot,
  required Map<String, dynamic> body,
}) {
  final architecture = architectureConfigFromBody(body);
  final api = apiConfigFromBody(body);
  final patch = <String, dynamic>{
    'architecture': architecture.toJson(),
    'api': api.toJson(),
  };
  final sm = body['state_management'] as String?;
  if (sm != null && sm.trim().isNotEmpty) {
    patch['state_management'] = sm.trim();
  }
  return saveReleaseToolkitConfigPatch(projectRoot: projectRoot, patch: patch);
}
