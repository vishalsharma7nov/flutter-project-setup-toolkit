import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'architecture_config.dart';
import 'architecture_preset.dart';
import 'feature_naming.dart';

/// Mason-style feature layout loaded from config or a JSON file.
class CustomArchitectureTemplate {
  const CustomArchitectureTemplate({
    required this.featureBasePathTemplate,
    required this.directories,
    required this.files,
  });

  factory CustomArchitectureTemplate.fromJson(Map<String, dynamic> json) {
    return CustomArchitectureTemplate(
      featureBasePathTemplate: json['feature_base_path'] as String? ??
          'lib/features/{{feature}}',
      directories: _stringList(json['directories']),
      files: _stringList(json['files']),
    );
  }

  final String featureBasePathTemplate;
  final List<String> directories;
  final List<String> files;

  static List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value.map((entry) => '$entry').toList();
  }

  ResolvedCustomTemplate resolve({
    required String featureName,
    required String filePrefix,
  }) {
    final vars = TemplateVariables(feature: featureName, prefix: filePrefix);
    return ResolvedCustomTemplate(
      featureRoot: vars.substitute(featureBasePathTemplate),
      directories: directories.map(vars.substitute).toList(),
      files: files.map(vars.substitute).toList(),
    );
  }
}

class ResolvedCustomTemplate {
  const ResolvedCustomTemplate({
    required this.featureRoot,
    required this.directories,
    required this.files,
  });

  final String featureRoot;
  final List<String> directories;
  final List<String> files;
}

class TemplateVariables {
  TemplateVariables({required this.feature, required this.prefix});

  final String feature;
  final String prefix;

  String get featureSnake =>
      prefix.endsWith('_') ? prefix.substring(0, prefix.length - 1) : prefix;

  String get pascalCase => featureNameToPascalCase(feature);

  String substitute(String input) {
    return input
        .replaceAll('{{feature}}', feature)
        .replaceAll('{{prefix}}', prefix)
        .replaceAll('{{Prefix}}', pascalCase)
        .replaceAll('{{feature_snake}}', featureSnake);
  }
}

CustomArchitectureTemplate loadCustomArchitectureTemplate({
  required Directory projectRoot,
  required ArchitectureConfig architecture,
}) {
  if (architecture.preset != ArchitecturePreset.custom) {
    throw StateError('Custom template loading requires preset "custom"');
  }

  if (architecture.customTemplate != null) {
    return CustomArchitectureTemplate.fromJson(architecture.customTemplate!);
  }

  final templatePath = architecture.customTemplatePath;
  if (templatePath == null || templatePath.trim().isEmpty) {
    throw StateError(
      'Custom architecture preset requires architecture.custom_template '
      'or architecture.custom_template_path in release-toolkit.config.json',
    );
  }

  final file = p.isAbsolute(templatePath)
      ? File(templatePath)
      : File(p.join(projectRoot.path, templatePath));
  if (!file.existsSync()) {
    throw StateError('Custom template not found: ${file.path}');
  }

  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map<String, dynamic>) {
    throw StateError('Custom template must be a JSON object: ${file.path}');
  }
  return CustomArchitectureTemplate.fromJson(decoded);
}

List<String> customTemplatePreviewPaths({
  required Directory projectRoot,
  required ArchitectureConfig architecture,
  required String featureName,
  required String filePrefix,
}) {
  final template = loadCustomArchitectureTemplate(
    projectRoot: projectRoot,
    architecture: architecture,
  );
  final resolved = template.resolve(
    featureName: featureName,
    filePrefix: filePrefix,
  );
  return [
    for (final dir in resolved.directories) p.join(resolved.featureRoot, dir),
    for (final file in resolved.files) p.join(resolved.featureRoot, file),
  ];
}
