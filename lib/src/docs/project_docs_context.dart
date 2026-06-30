import 'dart:io';

import 'package:path/path.dart' as p;

import '../architecture/architecture_audit.dart';
import '../config.dart';
import '../doctor/project_doctor.dart';
import '../qa/codebase_snapshot.dart';

/// Collected analysis used to generate project documentation.
class ProjectDocsContext {
  const ProjectDocsContext({
    required this.projectRoot,
    required this.snapshot,
    required this.audit,
    required this.doctor,
    required this.config,
    required this.configError,
    required this.scripts,
    required this.existingDocs,
    required this.existingReadme,
    required this.hasToolkitConfig,
    required this.hasCiWorkflow,
  });

  final Directory projectRoot;
  final CodebaseSnapshot snapshot;
  final ArchitectureAuditReport audit;
  final ProjectDoctorReport doctor;
  final ToolkitConfig? config;
  final String? configError;
  final List<String> scripts;
  final Map<String, bool> existingDocs;
  final String? existingReadme;
  final bool hasToolkitConfig;
  final bool hasCiWorkflow;

  Map<String, dynamic> toJson() => {
        'project_path': projectRoot.path,
        'project_name': snapshot.projectName,
        'rough_purpose': snapshot.roughPurpose,
        'feature_modules': snapshot.featureModules,
        'screens': snapshot.screens,
        'platforms': snapshot.platforms,
        'dart_file_count': snapshot.dartFiles.length,
        'test_file_count': snapshot.testFiles.length,
        'configured_preset': audit.configuredPreset?.id,
        'detected_preset': audit.detection.suggestedPreset.id,
        'architecture_drift': audit.detection.drift,
        'architecture_issue_count': audit.issues.length,
        'has_toolkit_config': hasToolkitConfig,
        'has_ci_workflow': hasCiWorkflow,
        'scripts': scripts,
        'existing_docs': existingDocs,
        'doctor_warn_count': doctor.checks
            .where((check) => check.severity == 'warn')
            .length,
        'doctor_error_count': doctor.checks
            .where((check) => check.severity == 'error')
            .length,
        if (configError != null) 'config_error': configError,
      };
}

/// Scan [projectRoot] and assemble documentation context.
ProjectDocsContext gatherProjectDocsContext(Directory projectRoot) {
  validateFlutterProject(projectRoot);
  final root = projectRoot.absolute;

  final snapshot = analyzeCodebase(root);
  final audit = runArchitectureAudit(root);
  final doctor = runProjectDoctor(root);

  ToolkitConfig? config;
  String? configError;
  final configFile = File(p.join(root.path, 'release-toolkit.config.json'));
  final hasToolkitConfig = configFile.existsSync();
  if (hasToolkitConfig) {
    try {
      config = loadConfig(root);
    } on Object catch (e) {
      configError = '$e';
    }
  }

  final workflowsDir = Directory(p.join(root.path, '.github', 'workflows'));
  final hasCiWorkflow = workflowsDir.existsSync() &&
      workflowsDir
          .listSync()
          .any((entity) => entity is File && entity.path.endsWith('.yml'));

  return ProjectDocsContext(
    projectRoot: root,
    snapshot: snapshot,
    audit: audit,
    doctor: doctor,
    config: config,
    configError: configError,
    scripts: _listScripts(root),
    existingDocs: _scanExistingDocs(root),
    existingReadme: _readIfExists(File(p.join(root.path, 'README.md'))),
    hasToolkitConfig: hasToolkitConfig,
    hasCiWorkflow: hasCiWorkflow,
  );
}

List<String> _listScripts(Directory root) {
  final scriptsDir = Directory(p.join(root.path, 'scripts'));
  if (!scriptsDir.existsSync()) return [];
  return scriptsDir
      .listSync()
      .whereType<File>()
      .map((file) => p.basename(file.path))
      .where((name) => !name.startsWith('.'))
      .toList()
    ..sort();
}

Map<String, bool> _scanExistingDocs(Directory root) {
  final paths = ProjectDocsPaths.all;
  final result = <String, bool>{};
  for (final rel in paths) {
    result[rel] = File(p.join(root.path, rel)).existsSync();
  }
  return result;
}

String? _readIfExists(File file) =>
    file.existsSync() ? file.readAsStringSync() : null;

/// Relative documentation paths managed by Docs Studio.
abstract final class ProjectDocsPaths {
  static const readme = 'README.md';
  static const docIndex = 'doc/README.md';
  static const gettingStarted = 'doc/getting-started.md';
  static const architecture = 'doc/architecture.md';
  static const features = 'doc/features.md';
  static const configuration = 'doc/configuration.md';
  static const development = 'doc/development.md';
  static const building = 'doc/building.md';
  static const testing = 'doc/testing.md';

  static const all = [
    readme,
    docIndex,
    gettingStarted,
    architecture,
    features,
    configuration,
    development,
    building,
    testing,
  ];

  static const labels = {
    readme: 'README.md',
    docIndex: 'Documentation index',
    gettingStarted: 'Getting started',
    architecture: 'Architecture',
    features: 'Features',
    configuration: 'Configuration',
    development: 'Development',
    building: 'Building',
    testing: 'Testing',
  };
}
