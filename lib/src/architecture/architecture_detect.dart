import 'dart:io';

import 'package:path/path.dart' as p;

import 'architecture_preset.dart';

class ArchitectureDetectionResult {
  ArchitectureDetectionResult({
    required this.suggestedPreset,
    required this.confidence,
    required this.signals,
    this.configuredPreset,
    this.drift = false,
  });

  final ArchitecturePreset suggestedPreset;
  final ArchitecturePreset? configuredPreset;
  final double confidence;
  final List<String> signals;
  final bool drift;

  Map<String, dynamic> toJson() => {
        'suggested_preset': suggestedPreset.id,
        'configured_preset': configuredPreset?.id,
        'confidence': confidence,
        'signals': signals,
        'drift': drift,
        'matches_config': configuredPreset == null || !drift,
      };
}

ArchitectureDetectionResult detectArchitectureLayout(Directory projectRoot) {
  final libDir = Directory(p.join(projectRoot.path, 'lib'));
  if (!libDir.existsSync()) {
    return ArchitectureDetectionResult(
      suggestedPreset: ArchitecturePreset.defaultPreset,
      confidence: 0,
      signals: ['lib/ not found'],
    );
  }

  final signals = <String>[];
  var scores = <ArchitecturePreset, int>{};

  void score(ArchitecturePreset preset, int points, String signal) {
    scores[preset] = (scores[preset] ?? 0) + points;
    signals.add(signal);
  }

  if (Directory(p.join(projectRoot.path, 'packages')).existsSync()) {
    score(
      ArchitecturePreset.microFeature,
      4,
      'packages/ directory present',
    );
  }
  if (File(p.join(projectRoot.path, 'melos.yaml')).existsSync()) {
    score(ArchitecturePreset.microFeature, 2, 'melos.yaml present');
  }
  if (Directory(p.join(libDir.path, 'modules')).existsSync()) {
    score(ArchitecturePreset.getxModule, 3, 'lib/modules/ present');
  }
  if (Directory(p.join(libDir.path, 'ui')).existsSync()) {
    score(ArchitecturePreset.compassMvvm, 3, 'lib/ui/ present');
  }
  if (Directory(p.join(libDir.path, 'store')).existsSync()) {
    score(ArchitecturePreset.redux, 2, 'lib/store/ present');
  }

  final featuresDir = Directory(p.join(libDir.path, 'features'));
  if (featuresDir.existsSync()) {
    for (final entity in featuresDir.listSync()) {
      if (entity is! Directory) continue;
      final featurePath = entity.path;
      if (Directory(p.join(featurePath, 'data')).existsSync() &&
          Directory(p.join(featurePath, 'domain')).existsSync()) {
        score(
          ArchitecturePreset.featureFirstClean,
          3,
          'feature-first clean layers in ${p.basename(featurePath)}',
        );
      }
      if (Directory(p.join(featurePath, 'screens')).existsSync()) {
        score(ArchitecturePreset.simple, 2, 'simple screens in ${p.basename(featurePath)}');
      }
      if (Directory(p.join(featurePath, 'viewmodels')).existsSync()) {
        score(ArchitecturePreset.mvvm, 2, 'mvvm folders in ${p.basename(featurePath)}');
      }
      if (Directory(p.join(featurePath, 'controllers')).existsSync() &&
          Directory(p.join(featurePath, 'views')).existsSync()) {
        score(ArchitecturePreset.mvc, 2, 'mvc folders in ${p.basename(featurePath)}');
      }
      if (Directory(p.join(featurePath, 'ports')).existsSync() &&
          Directory(p.join(featurePath, 'adapters')).existsSync()) {
        score(ArchitecturePreset.hexagonal, 3, 'hexagonal in ${p.basename(featurePath)}');
      }
    }
  }

  if (Directory(p.join(libDir.path, 'data')).existsSync() &&
      Directory(p.join(libDir.path, 'presentation')).existsSync()) {
    score(ArchitecturePreset.layerFirstClean, 3, 'top-level layer-first roots');
  }

  if (scores.isEmpty) {
    return ArchitectureDetectionResult(
      suggestedPreset: ArchitecturePreset.defaultPreset,
      confidence: 0.2,
      signals: ['No strong layout signals — defaulting to feature_first_clean'],
    );
  }

  final best = scores.entries.reduce(
    (a, b) => a.value >= b.value ? a : b,
  );
  final total = scores.values.fold<int>(0, (sum, value) => sum + value);
  final confidence = (best.value / total).clamp(0.0, 1.0);

  return ArchitectureDetectionResult(
    suggestedPreset: best.key,
    confidence: confidence,
    signals: signals,
  );
}

ArchitectureDetectionResult detectArchitectureWithConfig({
  required Directory projectRoot,
  ArchitecturePreset? configuredPreset,
}) {
  final detected = detectArchitectureLayout(projectRoot);
  if (configuredPreset == null) {
    return detected;
  }
  final drift = configuredPreset != detected.suggestedPreset &&
      detected.confidence >= 0.45;
  return ArchitectureDetectionResult(
    suggestedPreset: detected.suggestedPreset,
    configuredPreset: configuredPreset,
    confidence: detected.confidence,
    signals: detected.signals,
    drift: drift,
  );
}
