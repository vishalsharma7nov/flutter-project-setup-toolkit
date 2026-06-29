import 'dart:io';

import 'package:path/path.dart' as p;

import '../config.dart';
import 'architecture_detect.dart';
import 'architecture_preset.dart';

class ArchitectureAuditIssue {
  ArchitectureAuditIssue({
    required this.severity,
    required this.code,
    required this.message,
    this.file,
  });

  final String severity;
  final String code;
  final String message;
  final String? file;

  Map<String, dynamic> toJson() => {
        'severity': severity,
        'code': code,
        'message': message,
        if (file != null) 'file': file,
      };
}

class ArchitectureAuditReport {
  ArchitectureAuditReport({
    required this.projectPath,
    required this.configuredPreset,
    required this.detection,
    required this.issues,
  });

  final String projectPath;
  final ArchitecturePreset? configuredPreset;
  final ArchitectureDetectionResult detection;
  final List<ArchitectureAuditIssue> issues;

  Map<String, dynamic> toJson() => {
        'project_path': projectPath,
        'configured_preset': configuredPreset?.id,
        'detection': detection.toJson(),
        'issues': issues.map((issue) => issue.toJson()).toList(),
        'issue_count': issues.length,
      };

  String toHumanReadable() {
    final buffer = StringBuffer()
      ..writeln('Architecture audit: $projectPath')
      ..writeln('Configured preset: ${configuredPreset?.id ?? '(none)'}')
      ..writeln(
        'Detected preset: ${detection.suggestedPreset.id} '
        '(${(detection.confidence * 100).toStringAsFixed(0)}% confidence)',
      );
    if (detection.drift) {
      buffer.writeln('Drift: configured preset differs from detected layout');
    }
    if (issues.isEmpty) {
      buffer.writeln('No issues found.');
    } else {
      buffer.writeln('Issues:');
      for (final issue in issues) {
        final location = issue.file == null ? '' : ' [${issue.file}]';
        buffer.writeln('  [${issue.severity}] ${issue.code}: ${issue.message}$location');
      }
    }
    return buffer.toString();
  }
}

ArchitectureAuditReport runArchitectureAudit(Directory projectRoot) {
  ArchitecturePreset? configured;
  try {
    configured = loadConfig(projectRoot).architecture.preset;
  } on Object {
    configured = null;
  }

  final detection = detectArchitectureWithConfig(
    projectRoot: projectRoot,
    configuredPreset: configured,
  );

  final issues = <ArchitectureAuditIssue>[];
  if (detection.drift) {
    issues.add(
      ArchitectureAuditIssue(
        severity: 'warn',
        code: 'preset_drift',
        message:
            'Config preset is ${configured?.id} but layout suggests ${detection.suggestedPreset.id}',
      ),
    );
  }

  issues.addAll(_scanPresentationDataImports(projectRoot));

  return ArchitectureAuditReport(
    projectPath: projectRoot.path,
    configuredPreset: configured,
    detection: detection,
    issues: issues,
  );
}

List<ArchitectureAuditIssue> _scanPresentationDataImports(Directory projectRoot) {
  final issues = <ArchitectureAuditIssue>[];
  final libDir = Directory(p.join(projectRoot.path, 'lib'));
  if (!libDir.existsSync()) return issues;

  final featuresDir = Directory(p.join(libDir.path, 'features'));
  if (!featuresDir.existsSync()) return issues;

  final featureNames = featuresDir
      .listSync()
      .whereType<Directory>()
      .map((dir) => p.basename(dir.path))
      .toSet();

  for (final featureDir in featuresDir.listSync().whereType<Directory>()) {
    final featureName = p.basename(featureDir.path);
    final presentation = Directory(p.join(featureDir.path, 'presentation'));
    if (!presentation.existsSync()) continue;

    for (final entity in presentation.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final content = entity.readAsStringSync();
      final importPattern = RegExp(r"import\s+'package:[^']+/features/([^/]+)/data/");
      for (final match in importPattern.allMatches(content)) {
        final importedFeature = match.group(1);
        if (importedFeature != null && importedFeature != featureName) {
          issues.add(
            ArchitectureAuditIssue(
              severity: 'error',
              code: 'cross_feature_data_import',
              message:
                  "Presentation imports another feature's data layer ($importedFeature)",
              file: p.relative(entity.path, from: projectRoot.path),
            ),
          );
        }
      }
    }
  }

  // Package-relative imports: features/foo/presentation importing features/bar/data
  for (final featureDir in featuresDir.listSync().whereType<Directory>()) {
    final featureName = p.basename(featureDir.path);
    final presentation = Directory(p.join(featureDir.path, 'presentation'));
    if (!presentation.existsSync()) continue;
    for (final entity in presentation.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final content = entity.readAsStringSync();
      final relativePattern = RegExp(r"import\s+'\../\../([^/]+)/data/");
      for (final match in relativePattern.allMatches(content)) {
        final importedFeature = match.group(1);
        if (importedFeature != null &&
            featureNames.contains(importedFeature) &&
            importedFeature != featureName) {
          issues.add(
            ArchitectureAuditIssue(
              severity: 'error',
              code: 'cross_feature_data_import',
              message:
                  "Presentation imports another feature's data layer ($importedFeature)",
              file: p.relative(entity.path, from: projectRoot.path),
            ),
          );
        }
      }
    }
  }

  return issues;
}
