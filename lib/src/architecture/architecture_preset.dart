import '../models.dart';

/// Folder-layout presets for Flutter projects.
enum ArchitecturePreset {
  featureFirstClean('feature_first_clean'),
  layerFirstClean('layer_first_clean'),
  compassMvvm('compass_mvvm'),
  simple('simple'),
  mvvm('mvvm'),
  mvc('mvc'),
  mvi('mvi'),
  redux('redux'),
  hexagonal('hexagonal'),
  blocCentric('bloc_centric'),
  riverpodFirst('riverpod_first'),
  getxModule('getx_module'),
  stacked('stacked'),
  microFeature('micro_feature'),
  custom('custom');

  const ArchitecturePreset(this.id);

  final String id;

  static ArchitecturePreset get defaultPreset => featureFirstClean;

  static ArchitecturePreset? parse(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final preset in ArchitecturePreset.values) {
      if (preset.id == value || preset.name == value) {
        return preset;
      }
    }
    return null;
  }

  String get label => switch (this) {
        featureFirstClean => 'Feature-first clean architecture',
        layerFirstClean => 'Layer-first clean architecture',
        compassMvvm => 'Flutter Compass / MVVM hybrid',
        simple => 'Simple (screens + services)',
        mvvm => 'MVVM',
        mvc => 'MVC',
        mvi => 'MVI',
        redux => 'Redux',
        hexagonal => 'Hexagonal (ports & adapters)',
        blocCentric => 'BLoC-centric clean arch',
        riverpodFirst => 'Riverpod-first clean arch',
        getxModule => 'GetX module',
        stacked => 'Stacked (MVVM)',
        microFeature => 'Micro-feature monorepo (melos)',
        custom => 'Custom JSON template',
      };

  /// Presets with dedicated folder trees in the architecture scaffold engine.
  bool get hasFullLayoutSupport => switch (this) {
        featureFirstClean ||
        layerFirstClean ||
        compassMvvm ||
        simple ||
        mvvm ||
        mvc ||
        mvi ||
        redux ||
        hexagonal ||
        blocCentric ||
        riverpodFirst ||
        getxModule ||
        stacked ||
        microFeature ||
        custom =>
          true,
      };

  ArchitecturePreset get effectivePreset =>
      hasFullLayoutSupport ? this : featureFirstClean;

  String get defaultFeatureBasePath => switch (this) {
        compassMvvm => 'lib/ui',
        getxModule => 'lib/modules',
        microFeature => 'packages',
        custom => 'lib/features',
        _ => 'lib/features',
      };

  StateManagement? get suggestedStateManagement => switch (this) {
        blocCentric => StateManagement.bloc,
        riverpodFirst => StateManagement.riverpod,
        getxModule => StateManagement.getx,
        _ => null,
      };

  bool get requiresCustomTemplate => this == ArchitecturePreset.custom;
}
