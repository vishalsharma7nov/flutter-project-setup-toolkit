import 'architecture_preset.dart';
import 'architecture_core_modules.dart';

class ArchitectureLayersConfig {
  const ArchitectureLayersConfig({
    this.domain = true,
    this.data = true,
    this.presentation = true,
    this.useCases = true,
  });

  factory ArchitectureLayersConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ArchitectureLayersConfig();
    return ArchitectureLayersConfig(
      domain: json['domain'] as bool? ?? true,
      data: json['data'] as bool? ?? true,
      presentation: json['presentation'] as bool? ?? true,
      useCases: json['use_cases'] as bool? ?? true,
    );
  }

  final bool domain;
  final bool data;
  final bool presentation;
  final bool useCases;

  Map<String, dynamic> toJson() => {
        'domain': domain,
        'data': data,
        'presentation': presentation,
        'use_cases': useCases,
      };
}

class ArchitectureBootstrapConfig {
  const ArchitectureBootstrapConfig({
    this.core = true,
    this.appRouter = true,
    this.shared = false,
    this.melos = false,
    this.flavorMains = false,
    this.scaffoldTestMirror = false,
    this.autoWire = false,
  });

  factory ArchitectureBootstrapConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ArchitectureBootstrapConfig();
    return ArchitectureBootstrapConfig(
      core: json['core'] as bool? ?? true,
      appRouter: json['app_router'] as bool? ?? true,
      shared: json['shared'] as bool? ?? false,
      melos: json['melos'] as bool? ?? false,
      flavorMains: json['flavor_mains'] as bool? ?? false,
      scaffoldTestMirror: json['scaffold_test_mirror'] as bool? ?? false,
      autoWire: json['auto_wire'] as bool? ?? false,
    );
  }

  final bool core;
  final bool appRouter;
  final bool shared;
  final bool melos;
  final bool flavorMains;
  final bool scaffoldTestMirror;
  final bool autoWire;

  Map<String, dynamic> toJson() => {
        'core': core,
        'app_router': appRouter,
        'shared': shared,
        'melos': melos,
        'flavor_mains': flavorMains,
        'scaffold_test_mirror': scaffoldTestMirror,
        'auto_wire': autoWire,
      };
}

enum ProjectRouting {
  none,
  goRouter,
  autoRoute;

  static ProjectRouting? parse(String? value) {
    if (value == null || value.isEmpty) return null;
    return switch (value) {
      'go_router' => goRouter,
      'auto_route' => autoRoute,
      'none' => none,
      _ => null,
    };
  }

  String get id => switch (this) {
        none => 'none',
        goRouter => 'go_router',
        autoRoute => 'auto_route',
      };
}

enum DependencyInjectionStyle {
  none,
  getIt,
  injectable,
  riverpod;

  static DependencyInjectionStyle? parse(String? value) {
    if (value == null || value.isEmpty) return null;
    return switch (value) {
      'get_it' => getIt,
      'injectable' => injectable,
      'riverpod' => riverpod,
      'none' => none,
      _ => null,
    };
  }

  String get id => switch (this) {
        none => 'none',
        getIt => 'get_it',
        injectable => 'injectable',
        riverpod => 'riverpod',
      };
}

class ArchitectureConfig {
  const ArchitectureConfig({
    this.preset = ArchitecturePreset.featureFirstClean,
    this.featureBasePath = 'lib/features',
    this.layers = const ArchitectureLayersConfig(),
    this.bootstrap = const ArchitectureBootstrapConfig(),
    this.coreModules = const ArchitectureCoreModulesConfig(),
    this.routing = ProjectRouting.goRouter,
    this.dependencyInjection = DependencyInjectionStyle.getIt,
    this.scaffoldStarterCode = false,
    this.customTemplatePath,
    this.customTemplate,
  });

  factory ArchitectureConfig.defaults() => const ArchitectureConfig();

  factory ArchitectureConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ArchitectureConfig.defaults();
    final preset =
        ArchitecturePreset.parse(json['preset'] as String?) ??
            ArchitecturePreset.defaultPreset;
    final bootstrap = ArchitectureBootstrapConfig.fromJson(
      json['bootstrap'] as Map<String, dynamic>?,
    );
    return ArchitectureConfig(
      preset: preset,
      featureBasePath:
          json['feature_base_path'] as String? ?? preset.defaultFeatureBasePath,
      layers: ArchitectureLayersConfig.fromJson(
        json['layers'] as Map<String, dynamic>?,
      ),
      bootstrap: preset == ArchitecturePreset.microFeature
          ? ArchitectureBootstrapConfig(
              core: bootstrap.core,
              appRouter: bootstrap.appRouter,
              shared: bootstrap.shared,
              melos: bootstrap.melos || true,
              flavorMains: bootstrap.flavorMains,
              scaffoldTestMirror: bootstrap.scaffoldTestMirror,
            )
          : bootstrap,
      coreModules: ArchitectureCoreModulesConfig.fromJson(
        json['core_modules'] as Map<String, dynamic>?,
      ),
      routing:
          ProjectRouting.parse(json['routing'] as String?) ??
              ProjectRouting.goRouter,
      dependencyInjection:
          DependencyInjectionStyle.parse(
            json['dependency_injection'] as String?,
          ) ??
              DependencyInjectionStyle.getIt,
      scaffoldStarterCode: json['scaffold_starter_code'] as bool? ?? false,
      customTemplatePath: json['custom_template_path'] as String?,
      customTemplate: json['custom_template'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(
              json['custom_template'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  final ArchitecturePreset preset;
  final String featureBasePath;
  final ArchitectureLayersConfig layers;
  final ArchitectureBootstrapConfig bootstrap;
  final ArchitectureCoreModulesConfig coreModules;
  final ProjectRouting routing;
  final DependencyInjectionStyle dependencyInjection;
  final bool scaffoldStarterCode;
  final String? customTemplatePath;
  final Map<String, dynamic>? customTemplate;

  Map<String, dynamic> toJson() => {
        'preset': preset.id,
        'feature_base_path': featureBasePath,
        'layers': layers.toJson(),
        'bootstrap': bootstrap.toJson(),
        'core_modules': coreModules.toJson(),
        'routing': routing.id,
        'dependency_injection': dependencyInjection.id,
        'scaffold_starter_code': scaffoldStarterCode,
        if (customTemplatePath != null)
          'custom_template_path': customTemplatePath,
        if (customTemplate != null) 'custom_template': customTemplate,
      };

  ArchitectureConfig copyWith({
    ArchitecturePreset? preset,
    String? featureBasePath,
    ArchitectureLayersConfig? layers,
    ArchitectureBootstrapConfig? bootstrap,
    ArchitectureCoreModulesConfig? coreModules,
    ProjectRouting? routing,
    DependencyInjectionStyle? dependencyInjection,
    bool? scaffoldStarterCode,
    String? customTemplatePath,
    Map<String, dynamic>? customTemplate,
    bool clearCustomTemplatePath = false,
    bool clearCustomTemplate = false,
  }) {
    return ArchitectureConfig(
      preset: preset ?? this.preset,
      featureBasePath: featureBasePath ?? this.featureBasePath,
      layers: layers ?? this.layers,
      bootstrap: bootstrap ?? this.bootstrap,
      coreModules: coreModules ?? this.coreModules,
      routing: routing ?? this.routing,
      dependencyInjection: dependencyInjection ?? this.dependencyInjection,
      scaffoldStarterCode: scaffoldStarterCode ?? this.scaffoldStarterCode,
      customTemplatePath: clearCustomTemplatePath
          ? null
          : (customTemplatePath ?? this.customTemplatePath),
      customTemplate: clearCustomTemplate
          ? null
          : (customTemplate ?? this.customTemplate),
    );
  }
}
