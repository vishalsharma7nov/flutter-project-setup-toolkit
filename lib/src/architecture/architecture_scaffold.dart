import 'dart:io';

import 'package:path/path.dart' as p;

import '../api/api_config.dart';
import '../api/api_protocol.dart';
import '../config.dart';
import '../models.dart';
import 'architecture_config.dart';
import 'architecture_layers.dart';
import 'architecture_preset.dart';
import 'architecture_compatibility.dart';
import 'custom_architecture_template.dart';
import 'feature_naming.dart';
import 'feature_wiring.dart';
import 'micro_feature_scaffold.dart';
import 'starter_code.dart';
import 'test_mirror_scaffold.dart';

export 'architecture_audit.dart';
export 'architecture_compatibility.dart';
export 'architecture_core_modules.dart';
export 'architecture_detect.dart';
export 'core_modules_scaffold.dart';
export 'routing_scaffold.dart';
export 'test_mirror_scaffold.dart';
export 'architecture_config.dart';
export 'architecture_layers.dart';
export 'architecture_preset.dart';
export 'custom_architecture_template.dart';
export 'feature_naming.dart';
export 'micro_feature_scaffold.dart';
export 'project_bootstrap.dart';

class FeatureScaffoldResult {
  FeatureScaffoldResult({
    required this.featureName,
    required this.rootPath,
    required this.filePrefix,
    required this.stateManagement,
    required this.architecture,
    required this.createdPaths,
    required this.dryRun,
  });

  final String featureName;
  final String rootPath;
  final String filePrefix;
  final StateManagement stateManagement;
  final ArchitecturePreset architecture;
  final List<String> createdPaths;
  final bool dryRun;
}

ArchitectureConfig resolveArchitectureConfig(
  Directory projectRoot, {
  ArchitectureConfig? override,
}) {
  if (override != null) return override;
  return loadConfig(projectRoot).architecture;
}

ApiConfig resolveApiConfig(
  Directory projectRoot, {
  ApiConfig? override,
}) {
  if (override != null) return override;
  return loadConfig(projectRoot).api;
}

List<String> featureScaffoldRelativePaths(
  String prefix,
  StateManagement stateManagement, {
  ArchitecturePreset preset = ArchitecturePreset.featureFirstClean,
  ArchitectureLayersConfig layers = const ArchitectureLayersConfig(),
  ApiConfig? api,
}) {
  return architectureFeatureFilePaths(
    preset: preset,
    prefix: prefix,
    stateManagement: stateManagement,
    layers: layers,
    api: api,
  );
}

List<String> featureScaffoldDirectories(
  StateManagement stateManagement, {
  ArchitecturePreset preset = ArchitecturePreset.featureFirstClean,
  ArchitectureLayersConfig layers = const ArchitectureLayersConfig(),
}) {
  return architectureFeatureDirectories(
    preset: preset,
    stateManagement: stateManagement,
    layers: layers,
  );
}

Future<FeatureScaffoldResult> scaffoldFeature({
  required Directory projectRoot,
  required String featureName,
  String? basePath,
  StateManagement stateManagement = StateManagement.none,
  ArchitectureConfig? architecture,
  ApiConfig? api,
  bool dryRun = false,
}) async {
  validateFlutterProject(projectRoot);
  final arch = resolveArchitectureConfig(projectRoot, override: architecture);
  final apiConfig = resolveApiConfig(projectRoot, override: api);
  final trimmedName = featureName.trim();
  if (trimmedName.isEmpty) {
    throw ArgumentError('Feature name is required');
  }

  final prefix = featureNameToFilePrefix(trimmedName);
  final effectivePreset = arch.preset.effectivePreset;
  final normalizedBase = (basePath ?? arch.featureBasePath).replaceAll(r'\', '/');
  final createdPaths = <String>[];

  String starterFor(String relativeFile) {
    if (!arch.scaffoldStarterCode) return '';
    return starterCodeForPath(
      relativePath: relativeFile,
      featureName: trimmedName,
      filePrefix: prefix,
      preset: arch.preset,
      stateManagement: stateManagement,
      layers: arch.layers,
    );
  }

  void writeStubFile(File file, String displayPath, String relativeFile) {
    if (dryRun) {
      createdPaths.add(displayPath);
      return;
    }
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    if (!file.existsSync()) {
      file.writeAsStringSync(starterFor(relativeFile));
      createdPaths.add(displayPath);
    }
  }

  if (arch.preset == ArchitecturePreset.custom) {
    final template = loadCustomArchitectureTemplate(
      projectRoot: projectRoot,
      architecture: arch,
    );
    final resolved = template.resolve(
      featureName: trimmedName,
      filePrefix: prefix,
    );
    final featureRoot = Directory(p.join(projectRoot.path, resolved.featureRoot));
    for (final dir in resolved.directories) {
      final display = p.join(resolved.featureRoot, dir);
      if (dryRun) {
        createdPaths.add(display);
        continue;
      }
      Directory(p.join(featureRoot.path, dir)).createSync(recursive: true);
    }
    for (final relativeFile in resolved.files) {
      final displayPath = p.join(resolved.featureRoot, relativeFile);
      if (dryRun) {
        createdPaths.add(displayPath);
        continue;
      }
      final absoluteFile = File(p.join(featureRoot.path, relativeFile));
      if (!absoluteFile.parent.existsSync()) {
        absoluteFile.parent.createSync(recursive: true);
      }
      if (!absoluteFile.existsSync()) {
        writeStubFile(absoluteFile, displayPath, relativeFile);
      }
    }
    return _finishScaffold(
      projectRoot: projectRoot,
      arch: arch,
      featureName: trimmedName,
      result: FeatureScaffoldResult(
        featureName: trimmedName,
        rootPath: resolved.featureRoot,
        filePrefix: prefix,
        stateManagement: stateManagement,
        architecture: arch.preset,
        createdPaths: createdPaths,
        dryRun: dryRun,
      ),
    );
  }

  if (arch.preset == ArchitecturePreset.microFeature) {
    createdPaths.addAll(
      await scaffoldMicroFeaturePackage(
        projectRoot: projectRoot,
        featureName: trimmedName,
        filePrefix: prefix,
        stateManagement: stateManagement,
        architecture: arch,
        api: apiConfig,
        dryRun: dryRun,
      ),
    );
    return _finishScaffold(
      projectRoot: projectRoot,
      arch: arch,
      featureName: trimmedName,
      result: FeatureScaffoldResult(
        featureName: trimmedName,
        rootPath: p.join('packages', trimmedName),
        filePrefix: prefix,
        stateManagement: stateManagement,
        architecture: arch.preset,
        createdPaths: createdPaths,
        dryRun: dryRun,
      ),
    );
  }

  if (effectivePreset == ArchitecturePreset.layerFirstClean) {
    for (final (layerBase, name) in layerFirstFeatureRoots(
      featureName: trimmedName,
      layers: arch.layers,
    )) {
      final layerRoot = Directory(p.join(projectRoot.path, layerBase, name));
      for (final dir in layerFirstDirectories(
        layerBase: layerBase,
        layers: arch.layers,
        stateManagement: stateManagement,
      )) {
        final path = p.join(layerRoot.path, dir);
        final display = p.join(layerBase, name, dir);
        if (dryRun) {
          createdPaths.add(display);
        } else {
          Directory(path).createSync(recursive: true);
        }
      }
      for (final relative in layerFirstRelativePaths(
        layerBase: layerBase,
        featureName: trimmedName,
        prefix: prefix,
        stateManagement: stateManagement,
        layers: arch.layers,
        api: apiConfig,
      )) {
        final display = p.join(layerBase, name, relative);
        if (dryRun) {
          createdPaths.add(display);
          continue;
        }
        final file = File(p.join(layerRoot.path, relative));
        if (!file.parent.existsSync()) {
          file.parent.createSync(recursive: true);
        }
        if (!file.existsSync()) {
          file.writeAsStringSync(starterFor(relative));
          createdPaths.add(display);
        }
      }
    }

    return _finishScaffold(
      projectRoot: projectRoot,
      arch: arch,
      featureName: trimmedName,
      result: FeatureScaffoldResult(
        featureName: trimmedName,
        rootPath: 'lib/{data,domain,presentation}/$trimmedName',
        filePrefix: prefix,
        stateManagement: stateManagement,
        architecture: arch.preset,
        createdPaths: createdPaths,
        dryRun: dryRun,
      ),
    );
  }

  final featureRoot = Directory(
    p.join(projectRoot.path, normalizedBase, trimmedName),
  );

  for (final dir in architectureFeatureDirectories(
    preset: arch.preset,
    stateManagement: stateManagement,
    layers: arch.layers,
  )) {
    final path = p.join(featureRoot.path, dir);
    final display = p.join(normalizedBase, trimmedName, dir);
    if (dryRun) {
      createdPaths.add(display);
      continue;
    }
    Directory(path).createSync(recursive: true);
  }

  for (final relativeFile in architectureFeatureFilePaths(
    preset: arch.preset,
    prefix: prefix,
    stateManagement: stateManagement,
    layers: arch.layers,
    api: apiConfig,
  )) {
    final absoluteFile = File(p.join(featureRoot.path, relativeFile));
    final displayPath = p.join(normalizedBase, trimmedName, relativeFile);
    if (dryRun) {
      createdPaths.add(displayPath);
      continue;
    }
    writeStubFile(absoluteFile, displayPath, relativeFile);
  }

  return _finishScaffold(
    projectRoot: projectRoot,
    arch: arch,
    featureName: trimmedName,
    result: FeatureScaffoldResult(
      featureName: trimmedName,
      rootPath: p.join(normalizedBase, trimmedName),
      filePrefix: prefix,
      stateManagement: stateManagement,
      architecture: arch.preset,
      createdPaths: createdPaths,
      dryRun: dryRun,
    ),
  );
}

Future<FeatureScaffoldResult> _finishScaffold({
  required Directory projectRoot,
  required ArchitectureConfig arch,
  required String featureName,
  required FeatureScaffoldResult result,
}) async {
  var merged = result;

  if (arch.bootstrap.scaffoldTestMirror) {
    final dartPaths = merged.createdPaths.where((path) => path.endsWith('.dart'));
    final mirrors = testMirrorPathsForFeature(
      featureRoot: merged.rootPath,
      scaffoldedPaths: dartPaths.toList(),
    );
    final extra = <String>[];
    for (final mirror in mirrors) {
      if (merged.dryRun) {
        extra.add(mirror);
        continue;
      }
      final file = File(p.join(projectRoot.path, mirror));
      if (file.existsSync()) continue;
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(testMirrorStubContent(mirror));
      extra.add(mirror);
    }

    merged = FeatureScaffoldResult(
      featureName: merged.featureName,
      rootPath: merged.rootPath,
      filePrefix: merged.filePrefix,
      stateManagement: merged.stateManagement,
      architecture: merged.architecture,
      createdPaths: [...merged.createdPaths, ...extra],
      dryRun: merged.dryRun,
    );
  }

  if (arch.bootstrap.autoWire && !merged.dryRun) {
    wireFeatureIntoProject(
      projectRoot: projectRoot,
      featureName: featureName,
      architecture: arch,
    );
  }

  return merged;
}

void printFeatureScaffoldSummary(FeatureScaffoldResult result) {
  final verb = result.dryRun ? 'Would scaffold' : 'Scaffolded';
  print('$verb feature: ${result.featureName}');
  print('  Root: ${result.rootPath}');
  print('  Architecture: ${result.architecture.id}');
  print('  File prefix: ${result.filePrefix}');
  print('  State management: ${result.stateManagement.name}');
  if (result.createdPaths.isNotEmpty && !result.dryRun) {
    print('  Created ${result.createdPaths.length} stub file(s)');
  }
}

Map<String, dynamic> previewFeatureScaffold({
  required Directory projectRoot,
  required String featureName,
  required String basePath,
  required StateManagement stateManagement,
  ArchitectureConfig? architecture,
  ApiConfig? api,
}) {
  validateFlutterProject(projectRoot);
  final arch = resolveArchitectureConfig(projectRoot, override: architecture);
  final apiConfig = resolveApiConfig(projectRoot, override: api);
  final trimmed = featureName.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError('Feature name is required');
  }
  final prefix = featureNameToFilePrefix(trimmed);
  final normalizedBase = basePath.replaceAll(r'\', '/');

  if (arch.preset == ArchitecturePreset.custom) {
    final files = customTemplatePreviewPaths(
      projectRoot: projectRoot,
      architecture: arch,
      featureName: trimmed,
      filePrefix: prefix,
    );
    final rootPath = files.isEmpty
        ? normalizedBase
        : p.dirname(files.first);
    return {
      'feature_name': trimmed,
      'file_prefix': prefix,
      'root_path': rootPath,
      'architecture': arch.preset.id,
      'files': files,
      'already_exists': Directory(p.join(projectRoot.path, rootPath)).existsSync(),
    };
  }

  if (arch.preset == ArchitecturePreset.microFeature) {
    final files = microFeaturePreviewPaths(
      featureName: trimmed,
      filePrefix: prefix,
      stateManagement: stateManagement,
      architecture: arch,
      api: apiConfig,
    );
    final rootPath = p.join('packages', trimmed);
    return {
      'feature_name': trimmed,
      'file_prefix': prefix,
      'root_path': rootPath,
      'architecture': arch.preset.id,
      'files': files,
      'already_exists':
          Directory(p.join(projectRoot.path, rootPath)).existsSync(),
    };
  }

  final rootPath = p.join(normalizedBase, trimmed);
  final featureRoot = Directory(p.join(projectRoot.path, rootPath));

  final files = architectureFeatureFilePaths(
    preset: arch.preset,
    prefix: prefix,
    stateManagement: stateManagement,
    layers: arch.layers,
    api: apiConfig,
  ).map((f) => p.join(rootPath, f)).toList();

  return {
    'feature_name': trimmed,
    'file_prefix': prefix,
    'root_path': rootPath,
    'architecture': arch.preset.id,
    'files': files,
    'already_exists': featureRoot.existsSync(),
  };
}

Map<String, dynamic> detectFeatureProject(Directory projectRoot) {
  validateFlutterProject(projectRoot);
  final config = loadConfig(projectRoot);
  return {
    'project_path': projectRoot.path,
    'state_management': config.stateManagement.name,
    'state_management_options':
        StateManagement.values.map((v) => v.name).toList(),
    'architecture': config.architecture.preset.id,
    'architecture_options': architecturePresetOptions(),
    'architecture_option_groups': architecturePresetOptionGroups(),
    'api_protocol': config.api.protocol.id,
    'api_protocol_options': ApiProtocol.values.map((p) => p.id).toList(),
    'default_base_path': config.architecture.featureBasePath,
    'custom_template_path': config.architecture.customTemplatePath,
    if (config.api.externalSdk?.isConfigured == true)
      'external_sdk': config.api.externalSdk!.toJson(),
  };
}
