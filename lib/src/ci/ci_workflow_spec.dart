/// Configurable GitHub Actions workflow generation for CI Studio.
class CiWorkflowSpec {
  CiWorkflowSpec({
    this.preset = CiWorkflowPreset.full,
    this.pipelineMode = CiPipelineMode.split,
    this.analyze = true,
    this.formatCheck = true,
    this.architectureAudit = true,
    this.androidAab = true,
    this.iosIpa = true,
    this.uploadArtifacts = true,
    this.useToolkitScripts = false,
    this.onPush = true,
    this.onPullRequest = true,
    this.workflowDispatch = true,
    this.tagTrigger = false,
    this.firebaseAppDistribution = false,
    this.pathFilters = false,
    this.coverage = false,
    this.flutterVersion,
    this.toolkitPackage = 'flutter_project_setup_toolkit',
    this.defaultEnv = 'dev',
    this.environmentNames = const ['dev', 'prod'],
    this.actCompatFlutterX64 = false,
  });

  final CiWorkflowPreset preset;
  final CiPipelineMode pipelineMode;
  final bool analyze;
  final bool formatCheck;
  final bool architectureAudit;
  final bool androidAab;
  final bool iosIpa;
  final bool uploadArtifacts;
  final bool useToolkitScripts;
  final bool onPush;
  final bool onPullRequest;
  final bool workflowDispatch;
  final bool tagTrigger;
  final bool firebaseAppDistribution;
  final bool pathFilters;
  final bool coverage;
  final String? flutterVersion;
  final String toolkitPackage;
  final String defaultEnv;
  final List<String> environmentNames;
  final bool actCompatFlutterX64;

  factory CiWorkflowSpec.fromPreset(CiWorkflowPreset preset) {
    return switch (preset) {
      CiWorkflowPreset.prChecks => CiWorkflowSpec(
          preset: preset,
          pipelineMode: CiPipelineMode.single,
          analyze: true,
          formatCheck: true,
          architectureAudit: true,
          androidAab: false,
          iosIpa: false,
          onPush: false,
          onPullRequest: true,
          workflowDispatch: false,
        ),
      CiWorkflowPreset.release => CiWorkflowSpec(
          preset: preset,
          pipelineMode: CiPipelineMode.single,
          analyze: true,
          formatCheck: false,
          architectureAudit: true,
          androidAab: true,
          iosIpa: true,
          onPush: true,
          onPullRequest: false,
          workflowDispatch: true,
        ),
      CiWorkflowPreset.full => CiWorkflowSpec(
          preset: preset,
          pipelineMode: CiPipelineMode.split,
        ),
      CiWorkflowPreset.costConsciousWeeklyShip => CiWorkflowSpec(
          preset: preset,
          pipelineMode: CiPipelineMode.split,
          onPullRequest: true,
          onPush: true,
          workflowDispatch: true,
          tagTrigger: false,
          iosIpa: true,
          androidAab: true,
        ),
    };
  }

  factory CiWorkflowSpec.fromJson(Map<String, dynamic> json) {
    final presetRaw = json['preset'] as String?;
    final preset = CiWorkflowPreset.values.firstWhere(
      (p) => p.name == presetRaw,
      orElse: () => CiWorkflowPreset.full,
    );
    final base = CiWorkflowSpec.fromPreset(preset);
    return base.copyWith(
      pipelineMode: _parsePipelineMode(json['pipeline_mode'] as String?) ??
          base.pipelineMode,
      analyze: json['analyze'] as bool? ?? base.analyze,
      formatCheck: json['format_check'] as bool? ?? base.formatCheck,
      architectureAudit:
          json['architecture_audit'] as bool? ?? base.architectureAudit,
      androidAab: json['android_aab'] as bool? ?? base.androidAab,
      iosIpa: json['ios_ipa'] as bool? ?? base.iosIpa,
      uploadArtifacts: json['upload_artifacts'] as bool? ?? base.uploadArtifacts,
      useToolkitScripts:
          json['use_toolkit_scripts'] as bool? ?? base.useToolkitScripts,
      onPush: json['on_push'] as bool? ?? base.onPush,
      onPullRequest: json['on_pull_request'] as bool? ?? base.onPullRequest,
      workflowDispatch:
          json['workflow_dispatch'] as bool? ?? base.workflowDispatch,
      tagTrigger: json['tag_trigger'] as bool? ?? base.tagTrigger,
      firebaseAppDistribution: json['firebase_app_distribution'] as bool? ??
          base.firebaseAppDistribution,
      pathFilters: json['path_filters'] as bool? ?? base.pathFilters,
      coverage: json['coverage'] as bool? ?? base.coverage,
      flutterVersion: json['flutter_version'] as String? ?? base.flutterVersion,
      toolkitPackage:
          json['toolkit_package'] as String? ?? base.toolkitPackage,
      defaultEnv: json['default_env'] as String? ?? base.defaultEnv,
      environmentNames: _parseEnvNames(json['environment_names']) ??
          base.environmentNames,
      actCompatFlutterX64:
          json['act_compat_flutter_x64'] as bool? ?? base.actCompatFlutterX64,
    );
  }

  Map<String, dynamic> toJson() => {
        'preset': preset.name,
        'pipeline_mode': pipelineMode.name,
        'analyze': analyze,
        'format_check': formatCheck,
        'architecture_audit': architectureAudit,
        'android_aab': androidAab,
        'ios_ipa': iosIpa,
        'upload_artifacts': uploadArtifacts,
        'use_toolkit_scripts': useToolkitScripts,
        'on_push': onPush,
        'on_pull_request': onPullRequest,
        'workflow_dispatch': workflowDispatch,
        'tag_trigger': tagTrigger,
        'firebase_app_distribution': firebaseAppDistribution,
        'path_filters': pathFilters,
        'coverage': coverage,
        if (flutterVersion != null) 'flutter_version': flutterVersion,
        'toolkit_package': toolkitPackage,
        'default_env': defaultEnv,
        'environment_names': environmentNames,
        'act_compat_flutter_x64': actCompatFlutterX64,
      };

  CiWorkflowSpec copyWith({
    CiWorkflowPreset? preset,
    CiPipelineMode? pipelineMode,
    bool? analyze,
    bool? formatCheck,
    bool? architectureAudit,
    bool? androidAab,
    bool? iosIpa,
    bool? uploadArtifacts,
    bool? useToolkitScripts,
    bool? onPush,
    bool? onPullRequest,
    bool? workflowDispatch,
    bool? tagTrigger,
    bool? firebaseAppDistribution,
    bool? pathFilters,
    bool? coverage,
    String? flutterVersion,
    String? toolkitPackage,
    String? defaultEnv,
    List<String>? environmentNames,
    bool? actCompatFlutterX64,
  }) {
    return CiWorkflowSpec(
      preset: preset ?? this.preset,
      pipelineMode: pipelineMode ?? this.pipelineMode,
      analyze: analyze ?? this.analyze,
      formatCheck: formatCheck ?? this.formatCheck,
      architectureAudit: architectureAudit ?? this.architectureAudit,
      androidAab: androidAab ?? this.androidAab,
      iosIpa: iosIpa ?? this.iosIpa,
      uploadArtifacts: uploadArtifacts ?? this.uploadArtifacts,
      useToolkitScripts: useToolkitScripts ?? this.useToolkitScripts,
      onPush: onPush ?? this.onPush,
      onPullRequest: onPullRequest ?? this.onPullRequest,
      workflowDispatch: workflowDispatch ?? this.workflowDispatch,
      tagTrigger: tagTrigger ?? this.tagTrigger,
      firebaseAppDistribution:
          firebaseAppDistribution ?? this.firebaseAppDistribution,
      pathFilters: pathFilters ?? this.pathFilters,
      coverage: coverage ?? this.coverage,
      flutterVersion: flutterVersion ?? this.flutterVersion,
      toolkitPackage: toolkitPackage ?? this.toolkitPackage,
      defaultEnv: defaultEnv ?? this.defaultEnv,
      environmentNames: environmentNames ?? this.environmentNames,
      actCompatFlutterX64: actCompatFlutterX64 ?? this.actCompatFlutterX64,
    );
  }

  bool get hasCiJobs => analyze || formatCheck || architectureAudit;

  bool get hasReleaseJobs => androidAab || iosIpa || firebaseAppDistribution;
}

enum CiWorkflowPreset {
  prChecks,
  release,
  full,
  costConsciousWeeklyShip,
}

enum CiPipelineMode {
  single,
  split,
}

CiPipelineMode? _parsePipelineMode(String? raw) {
  if (raw == null) return null;
  return CiPipelineMode.values.firstWhere(
    (m) => m.name == raw,
    orElse: () => CiPipelineMode.single,
  );
}

List<String>? _parseEnvNames(Object? raw) {
  if (raw is! List) return null;
  return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
}
