import '../models.dart';
import 'architecture_preset.dart';

class ArchitectureCompatibilityWarning {
  ArchitectureCompatibilityWarning({
    required this.message,
    this.suggestedStateManagement,
  });

  final String message;
  final StateManagement? suggestedStateManagement;
}

ArchitectureCompatibilityWarning? architectureCompatibilityWarning({
  required ArchitecturePreset preset,
  required StateManagement stateManagement,
}) {
  if (preset == ArchitecturePreset.getxModule &&
      stateManagement != StateManagement.getx) {
    return ArchitectureCompatibilityWarning(
      message: "Preset '${preset.label}' requires getx state management.",
      suggestedStateManagement: StateManagement.getx,
    );
  }

  final suggested = preset.suggestedStateManagement;
  if (suggested != null && suggested != stateManagement) {
    return ArchitectureCompatibilityWarning(
      message:
          "Preset '${preset.label}' works best with ${suggested.name} state "
          'management (selected: ${stateManagement.name}).',
      suggestedStateManagement: suggested,
    );
  }

  if (preset == ArchitecturePreset.blocCentric &&
      stateManagement == StateManagement.getx) {
    return ArchitectureCompatibilityWarning(
      message: 'BLoC-centric preset is incompatible with getx.',
      suggestedStateManagement: StateManagement.bloc,
    );
  }
  if (preset == ArchitecturePreset.riverpodFirst &&
      stateManagement == StateManagement.getx) {
    return ArchitectureCompatibilityWarning(
      message: 'Riverpod-first preset is incompatible with getx.',
      suggestedStateManagement: StateManagement.riverpod,
    );
  }
  if (preset == ArchitecturePreset.blocCentric &&
      stateManagement == StateManagement.riverpod) {
    return ArchitectureCompatibilityWarning(
      message:
          'BLoC-centric preset is optimized for bloc — riverpod will use provider folders.',
      suggestedStateManagement: StateManagement.bloc,
    );
  }
  return null;
}

List<ArchitecturePreset> tierOnePresets() => [
      ArchitecturePreset.featureFirstClean,
      ArchitecturePreset.layerFirstClean,
      ArchitecturePreset.compassMvvm,
      ArchitecturePreset.simple,
    ];

List<ArchitecturePreset> tierTwoPresets() => [
      ArchitecturePreset.mvvm,
      ArchitecturePreset.mvc,
      ArchitecturePreset.mvi,
      ArchitecturePreset.redux,
      ArchitecturePreset.hexagonal,
    ];

List<ArchitecturePreset> tierThreePresets() => [
      ArchitecturePreset.blocCentric,
      ArchitecturePreset.riverpodFirst,
      ArchitecturePreset.getxModule,
      ArchitecturePreset.stacked,
    ];

List<ArchitecturePreset> tierFourPresets() => [
      ArchitecturePreset.microFeature,
      ArchitecturePreset.custom,
    ];

List<ArchitecturePreset> allScaffoldPresets() => [
      ...tierOnePresets(),
      ...tierTwoPresets(),
      ...tierThreePresets(),
      ...tierFourPresets(),
    ];

List<Map<String, String>> architecturePresetOptions() =>
    allScaffoldPresets()
        .map((preset) => {'id': preset.id, 'label': preset.label})
        .toList();

List<Map<String, dynamic>> architecturePresetOptionGroups() => [
      {
        'label': 'Core',
        'options': tierOnePresets()
            .map((p) => {'id': p.id, 'label': p.label})
            .toList(),
      },
      {
        'label': 'Pattern-based',
        'options': tierTwoPresets()
            .map((p) => {'id': p.id, 'label': p.label})
            .toList(),
      },
      {
        'label': 'State-management aligned',
        'options': tierThreePresets()
            .map((p) => {'id': p.id, 'label': p.label})
            .toList(),
      },
      {
        'label': 'Advanced',
        'options': tierFourPresets()
            .map((p) => {'id': p.id, 'label': p.label})
            .toList(),
      },
    ];
