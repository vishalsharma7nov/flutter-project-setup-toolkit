import '../api/api_config.dart';
import '../api/api_protocol.dart';
import '../models.dart';
import 'architecture_config.dart';
import 'architecture_preset.dart';

/// Relative directories under a feature root (or layer-first roots).
List<String> architectureFeatureDirectories({
  required ArchitecturePreset preset,
  required StateManagement stateManagement,
  required ArchitectureLayersConfig layers,
}) {
  return switch (preset.effectivePreset) {
    ArchitecturePreset.simple => [
      'screens',
      'widgets',
      'services',
    ],
    ArchitecturePreset.compassMvvm => [
      'view_models',
      'widgets',
    ],
    ArchitecturePreset.mvvm => [
      'models',
      'viewmodels',
      'views',
    ],
    ArchitecturePreset.mvc => [
      'models',
      'controllers',
      'views',
    ],
    ArchitecturePreset.mvi => [
      'models',
      'intents',
      'views',
      'reducers',
    ],
    ArchitecturePreset.redux => [
      'actions',
      'reducers',
      'state',
      'middleware',
    ],
    ArchitecturePreset.hexagonal => [
      'domain',
      'ports',
      'adapters',
    ],
    ArchitecturePreset.getxModule => [
      'bindings',
      'controllers',
      'views',
    ],
    ArchitecturePreset.stacked => [
      'views',
      'viewmodels',
      'services',
      'models',
    ],
    ArchitecturePreset.layerFirstClean => [
      if (layers.data) ...[
        'data/datasources',
        'data/repositories',
      ],
      if (layers.domain) ...[
        'domain/entities',
        'domain/repositories',
        if (layers.useCases) 'domain/usecases',
      ],
      if (layers.presentation) ...[
        'presentation/pages',
        'presentation/widgets',
        ..._presentationStateDirs(stateManagement),
      ],
    ],
    ArchitecturePreset.featureFirstClean ||
    ArchitecturePreset.blocCentric ||
    ArchitecturePreset.riverpodFirst ||
    ArchitecturePreset.microFeature ||
    ArchitecturePreset.custom =>
      [
        if (layers.data) ...[
          'data/datasources',
          'data/repositories',
        ],
        if (layers.domain) ...[
          'domain/entities',
          'domain/repositories',
          if (layers.useCases) 'domain/usecases',
        ],
        if (layers.presentation) ...[
          'presentation/pages',
          'presentation/widgets',
          ..._presentationStateDirs(stateManagement),
        ],
      ],
  };
}

List<String> _presentationStateDirs(StateManagement stateManagement) {
  return switch (stateManagement) {
    StateManagement.bloc => ['presentation/bloc'],
    StateManagement.riverpod || StateManagement.provider => [
      'presentation/providers',
    ],
    StateManagement.getx => ['presentation/controllers'],
    StateManagement.none => <String>[],
  };
}

List<String> architectureFeatureFilePaths({
  required ArchitecturePreset preset,
  required String prefix,
  required StateManagement stateManagement,
  required ArchitectureLayersConfig layers,
  ApiConfig? api,
}) {
  final effective = preset.effectivePreset;
  final remoteFile = _remoteDataSourceFile(prefix, api);

  return switch (effective) {
    ArchitecturePreset.simple => [
      'screens/${prefix}screen.dart',
      'widgets/${prefix}widget.dart',
      'services/${prefix}service.dart',
    ],
    ArchitecturePreset.compassMvvm => [
      'view_models/${prefix}view_model.dart',
      'widgets/${prefix}screen.dart',
    ],
    ArchitecturePreset.mvvm => [
      'models/${prefix}model.dart',
      'viewmodels/${prefix}view_model.dart',
      'views/${prefix}view.dart',
    ],
    ArchitecturePreset.mvc => [
      'models/${prefix}model.dart',
      'controllers/${prefix}controller.dart',
      'views/${prefix}view.dart',
    ],
    ArchitecturePreset.mvi => [
      'models/${prefix}model.dart',
      'intents/${prefix}intent.dart',
      'views/${prefix}view.dart',
      'reducers/${prefix}reducer.dart',
      '${prefix}state.dart',
    ],
    ArchitecturePreset.redux => [
      'actions/${prefix}actions.dart',
      'reducers/${prefix}reducer.dart',
      'state/${prefix}state.dart',
      'middleware/${prefix}middleware.dart',
    ],
    ArchitecturePreset.hexagonal => [
      'domain/${prefix}entity.dart',
      'domain/${prefix}usecase.dart',
      'ports/${prefix}repository_port.dart',
      'adapters/${prefix}api_adapter.dart',
    ],
    ArchitecturePreset.getxModule => [
      'bindings/${prefix}binding.dart',
      'controllers/${prefix}controller.dart',
      'views/${prefix}view.dart',
    ],
    ArchitecturePreset.stacked => [
      'views/${prefix}view.dart',
      'viewmodels/${prefix}viewmodel.dart',
      'services/${prefix}service.dart',
      'models/${prefix}model.dart',
    ],
    ArchitecturePreset.layerFirstClean ||
    ArchitecturePreset.featureFirstClean ||
    ArchitecturePreset.blocCentric ||
    ArchitecturePreset.riverpodFirst ||
    ArchitecturePreset.microFeature ||
    ArchitecturePreset.custom =>
      [
        if (layers.data) ...[
          'data/datasources/${prefix}local_data_source.dart',
          if (remoteFile != null) remoteFile,
          'data/repositories/${prefix}repository_impl.dart',
        ],
        if (layers.domain) ...[
          'domain/entities/${prefix}entity.dart',
          'domain/repositories/${prefix}repository.dart',
          if (layers.useCases) 'domain/usecases/${prefix}usecase.dart',
        ],
        ..._presentationFiles(prefix, stateManagement, layers.presentation),
      ],
  };
}

String? _remoteDataSourceFile(String prefix, ApiConfig? api) {
  final config = api ?? ApiConfig.defaults();
  if (config.usesExternalSdk) {
    return 'data/datasources/${prefix}sdk_data_source.dart';
  }
  return switch (config.protocol) {
    ApiProtocol.grpc => 'data/datasources/${prefix}grpc_service.dart',
    ApiProtocol.graphql => 'data/datasources/${prefix}graphql_queries.dart',
    ApiProtocol.localOnly => null,
    _ => 'data/datasources/${prefix}remote_data_source.dart',
  };
}

List<String> _presentationFiles(
  String prefix,
  StateManagement stateManagement,
  bool includePresentation,
) {
  if (!includePresentation) return [];
  return switch (stateManagement) {
    StateManagement.bloc => [
      'presentation/pages/${prefix}page.dart',
      'presentation/widgets/${prefix}widget.dart',
      'presentation/bloc/${prefix}bloc.dart',
      'presentation/bloc/${prefix}event.dart',
      'presentation/bloc/${prefix}state.dart',
    ],
    StateManagement.riverpod => [
      'presentation/pages/${prefix}page.dart',
      'presentation/widgets/${prefix}widget.dart',
      'presentation/providers/${prefix}provider.dart',
      'presentation/providers/${prefix}notifier.dart',
    ],
    StateManagement.provider => [
      'presentation/pages/${prefix}page.dart',
      'presentation/widgets/${prefix}widget.dart',
      'presentation/providers/${prefix}provider.dart',
    ],
    StateManagement.getx => [
      'presentation/pages/${prefix}page.dart',
      'presentation/widgets/${prefix}widget.dart',
      'presentation/controllers/${prefix}controller.dart',
    ],
    StateManagement.none => [
      'presentation/pages/${prefix}page.dart',
      'presentation/widgets/${prefix}widget.dart',
    ],
  };
}

/// Layer-first layout uses separate roots under lib/.
List<(String basePath, String featureName)> layerFirstFeatureRoots({
  required String featureName,
  required ArchitectureLayersConfig layers,
}) {
  final roots = <(String, String)>[];
  if (layers.data) {
    roots.add(('lib/data', featureName));
  }
  if (layers.domain) {
    roots.add(('lib/domain', featureName));
  }
  if (layers.presentation) {
    roots.add(('lib/presentation', featureName));
  }
  return roots;
}

List<String> layerFirstRelativePaths({
  required String layerBase,
  required String featureName,
  required String prefix,
  required StateManagement stateManagement,
  required ArchitectureLayersConfig layers,
  ApiConfig? api,
}) {
  if (layerBase == 'lib/data') {
    final remote = _remoteDataSourceFile(prefix, api);
    return [
      'datasources/${prefix}local_data_source.dart',
      if (remote != null) remote.replaceFirst('data/', ''),
      'repositories/${prefix}repository_impl.dart',
    ];
  }
  if (layerBase == 'lib/domain') {
    return [
      'entities/${prefix}entity.dart',
      'repositories/${prefix}repository.dart',
      if (layers.useCases) 'usecases/${prefix}usecase.dart',
    ];
  }
  if (layerBase == 'lib/presentation') {
    return [
      'pages/${prefix}page.dart',
      'widgets/${prefix}widget.dart',
      ..._presentationFiles(prefix, stateManagement, true)
          .map((p) => p.replaceFirst('presentation/', '')),
    ];
  }
  return [];
}

List<String> layerFirstDirectories({
  required String layerBase,
  required ArchitectureLayersConfig layers,
  required StateManagement stateManagement,
}) {
  if (layerBase == 'lib/data') {
    return ['datasources', 'repositories'];
  }
  if (layerBase == 'lib/domain') {
    return [
      'entities',
      'repositories',
      if (layers.useCases) 'usecases',
    ];
  }
  if (layerBase == 'lib/presentation') {
    return [
      'pages',
      'widgets',
      ..._presentationStateDirs(stateManagement)
          .map((d) => d.replaceFirst('presentation/', '')),
    ];
  }
  return [];
}
