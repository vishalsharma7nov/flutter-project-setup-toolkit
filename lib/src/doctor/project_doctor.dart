import 'dart:io';

import 'package:path/path.dart' as p;

import '../config.dart';
import '../flutter_tools.dart';
import '../architecture/architecture_audit.dart';
import '../architecture/architecture_detect.dart';

class DoctorCheck {
  DoctorCheck({
    required this.id,
    required this.severity,
    required this.message,
    this.fix,
  });

  final String id;
  final String severity;
  final String message;
  final String? fix;

  Map<String, dynamic> toJson() => {
        'id': id,
        'severity': severity,
        'message': message,
        if (fix != null) 'fix': fix,
      };
}

class ProjectDoctorReport {
  ProjectDoctorReport({
    required this.projectPath,
    required this.checks,
  });

  final String projectPath;
  final List<DoctorCheck> checks;

  bool get hasErrors =>
      checks.any((check) => check.severity == 'error');

  Map<String, dynamic> toJson() => {
        'project_path': projectPath,
        'checks': checks.map((c) => c.toJson()).toList(),
        'error_count':
            checks.where((c) => c.severity == 'error').length,
        'warn_count':
            checks.where((c) => c.severity == 'warn').length,
      };

  String toHumanReadable() {
    final buffer = StringBuffer()..writeln('Project doctor: $projectPath');
    if (checks.isEmpty) {
      buffer.writeln('All checks passed.');
      return buffer.toString();
    }
    for (final check in checks) {
      buffer.writeln('[${check.severity}] ${check.id}: ${check.message}');
      if (check.fix != null) {
        buffer.writeln('  Fix: ${check.fix}');
      }
    }
    return buffer.toString();
  }
}

ProjectDoctorReport runProjectDoctor(Directory projectRoot) {
  final checks = <DoctorCheck>[];

  try {
    final dart = Process.runSync('which', ['dart']);
    if (dart.exitCode != 0) {
      throw StateError('Dart not on PATH');
    }
    checks.add(
      DoctorCheck(
        id: 'dart_sdk',
        severity: 'ok',
        message: 'Dart SDK available',
      ),
    );
  } on Object catch (e) {
    checks.add(
      DoctorCheck(
        id: 'dart_sdk',
        severity: 'error',
        message: '$e',
        fix: 'Install Dart SDK: https://dart.dev/get-dart',
      ),
    );
  }

  try {
    detectFlutter();
    checks.add(
      DoctorCheck(
        id: 'flutter_sdk',
        severity: 'ok',
        message: 'Flutter SDK available',
      ),
    );
  } on Object catch (e) {
    checks.add(
      DoctorCheck(
        id: 'flutter_sdk',
        severity: 'warn',
        message: '$e',
        fix: 'Install Flutter and run flutter doctor',
      ),
    );
  }

  final configFile = File(p.join(projectRoot.path, 'release-toolkit.config.json'));
  if (configFile.existsSync()) {
    checks.add(
      DoctorCheck(
        id: 'toolkit_config',
        severity: 'ok',
        message: 'release-toolkit.config.json present',
      ),
    );
    try {
      final config = loadConfig(projectRoot);
      for (final entry in config.environments.entries) {
        final envFile = File(p.join(projectRoot.path, entry.value));
        if (!envFile.existsSync()) {
          checks.add(
            DoctorCheck(
              id: 'env_file_${entry.key}',
              severity: 'warn',
              message: 'Missing env file for ${entry.key}: ${entry.value}',
              fix: 'Run setup_project or create ${entry.value}',
            ),
          );
        }
      }
    } on Object catch (e) {
      checks.add(
        DoctorCheck(
          id: 'toolkit_config_parse',
          severity: 'error',
          message: 'Config parse error: $e',
          fix: 'Fix release-toolkit.config.json syntax',
        ),
      );
    }
  } else {
    checks.add(
      DoctorCheck(
        id: 'toolkit_config',
        severity: 'warn',
        message: 'No release-toolkit.config.json',
        fix: 'Run setup_project or open Setup Studio',
      ),
    );
  }

  final workflowsDir = Directory(p.join(projectRoot.path, '.github', 'workflows'));
  final hasCiWorkflow = workflowsDir.existsSync() &&
      workflowsDir
          .listSync()
          .any((entity) => entity is File && entity.path.endsWith('.yml'));
  if (!hasCiWorkflow) {
    checks.add(
      DoctorCheck(
        id: 'ci_workflow',
        severity: 'info',
        message: 'No GitHub Actions workflow in .github/workflows/',
        fix: 'Open CI Studio (dart run :toolkit_studio --view ci)',
      ),
    );
  }

  final androidKey = File(p.join(projectRoot.path, 'android/key.properties'));
  if (Directory(p.join(projectRoot.path, 'android')).existsSync()) {
    if (!androidKey.existsSync()) {
      checks.add(
        DoctorCheck(
          id: 'android_signing',
          severity: 'info',
          message: 'android/key.properties not found (needed for release builds)',
          fix: 'Create key.properties with storeFile, storePassword, keyAlias, keyPassword',
        ),
      );
    }
  }

  if (Platform.isMacOS &&
      Directory(p.join(projectRoot.path, 'ios')).existsSync()) {
    checks.add(
      DoctorCheck(
        id: 'ios_signing',
        severity: 'info',
        message: 'Configure signing in Xcode for release IPA',
        fix: 'Open ios/Runner.xcworkspace and set team + provisioning',
      ),
    );
  }

  try {
    validateFlutterProject(projectRoot);
    final audit = runArchitectureAudit(projectRoot);
    final detection = detectArchitectureLayout(projectRoot);
    if (audit.detection.drift) {
      checks.add(
        DoctorCheck(
          id: 'architecture_drift',
          severity: 'warn',
          message:
              'Layout suggests ${detection.suggestedPreset.id} but config is ${audit.configuredPreset?.id}',
          fix: 'Run architecture_audit --migrate or update architecture.preset',
        ),
      );
    }
    for (final issue in audit.issues) {
      if (issue.severity == 'error') {
        checks.add(
          DoctorCheck(
            id: issue.code,
            severity: 'error',
            message: issue.message,
            fix: 'See doc/architecture-audit.md',
          ),
        );
      }
    }
  } on Object catch (e) {
    checks.add(
      DoctorCheck(
        id: 'flutter_project',
        severity: 'error',
        message: '$e',
        fix: 'Point doctor at a valid Flutter project root',
      ),
    );
  }

  return ProjectDoctorReport(
    projectPath: projectRoot.path,
    checks: checks.where((c) => c.severity != 'ok').toList(),
  );
}
