import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/architecture/architecture_compatibility.dart';
import 'package:flutter_project_setup_toolkit/src/architecture/architecture_config.dart';
import 'package:flutter_project_setup_toolkit/src/architecture/architecture_layers.dart';
import 'package:flutter_project_setup_toolkit/src/architecture/architecture_preset.dart';
import 'package:flutter_project_setup_toolkit/src/architecture/architecture_scaffold.dart';
import 'package:flutter_project_setup_toolkit/src/architecture/project_bootstrap.dart';
import 'package:flutter_project_setup_toolkit/src/models.dart';
import 'package:test/test.dart';

void main() {
  group('Tier 2 pattern presets', () {
    test('mvvm uses models viewmodels views', () {
      final dirs = architectureFeatureDirectories(
        preset: ArchitecturePreset.mvvm,
        stateManagement: StateManagement.none,
        layers: const ArchitectureLayersConfig(),
      );
      expect(dirs, ['models', 'viewmodels', 'views']);

      final files = architectureFeatureFilePaths(
        preset: ArchitecturePreset.mvvm,
        prefix: 'auth_',
        stateManagement: StateManagement.none,
        layers: const ArchitectureLayersConfig(),
      );
      expect(files, contains('viewmodels/auth_view_model.dart'));
    });

    test('mvi includes root state file', () {
      final files = architectureFeatureFilePaths(
        preset: ArchitecturePreset.mvi,
        prefix: 'cart_',
        stateManagement: StateManagement.none,
        layers: const ArchitectureLayersConfig(),
      );
      expect(files, contains('cart_state.dart'));
      expect(files, contains('intents/cart_intent.dart'));
    });

    test('redux uses actions reducers state middleware', () {
      final dirs = architectureFeatureDirectories(
        preset: ArchitecturePreset.redux,
        stateManagement: StateManagement.none,
        layers: const ArchitectureLayersConfig(),
      );
      expect(dirs, contains('middleware'));

      final files = architectureFeatureFilePaths(
        preset: ArchitecturePreset.redux,
        prefix: 'app_',
        stateManagement: StateManagement.none,
        layers: const ArchitectureLayersConfig(),
      );
      expect(files, contains('actions/app_actions.dart'));
    });

    test('hexagonal uses domain ports adapters', () {
      final files = architectureFeatureFilePaths(
        preset: ArchitecturePreset.hexagonal,
        prefix: 'pay_',
        stateManagement: StateManagement.none,
        layers: const ArchitectureLayersConfig(),
      );
      expect(files, contains('ports/pay_repository_port.dart'));
      expect(files, contains('adapters/pay_api_adapter.dart'));
    });
  });

  group('Tier 3 stack-aligned presets', () {
    test('getx module uses lib/modules base path', () {
      expect(
        ArchitecturePreset.getxModule.defaultFeatureBasePath,
        'lib/modules',
      );
    });

    test('getx module scaffolds bindings controllers views', () async {
      final project = _minimalProject();
      addTearDown(() => project.deleteSync(recursive: true));

      final result = await scaffoldFeature(
        projectRoot: project,
        featureName: 'profile',
        basePath: 'lib/modules',
        stateManagement: StateManagement.getx,
        architecture: const ArchitectureConfig(
          preset: ArchitecturePreset.getxModule,
          featureBasePath: 'lib/modules',
        ),
      );

      expect(result.rootPath, 'lib/modules/profile');
      expect(
        File('${project.path}/lib/modules/profile/bindings/profile_binding.dart')
            .existsSync(),
        isTrue,
      );
    });

    test('stacked scaffolds viewmodel and service stubs', () async {
      final project = _minimalProject();
      addTearDown(() => project.deleteSync(recursive: true));

      await scaffoldFeature(
        projectRoot: project,
        featureName: 'home',
        architecture: const ArchitectureConfig(
          preset: ArchitecturePreset.stacked,
        ),
      );

      expect(
        File('${project.path}/lib/features/home/viewmodels/home_viewmodel.dart')
            .existsSync(),
        isTrue,
      );
    });

    test('bloc_centric keeps clean-arch data layer', () async {
      final project = _minimalProject();
      addTearDown(() => project.deleteSync(recursive: true));

      await scaffoldFeature(
        projectRoot: project,
        featureName: 'orders',
        stateManagement: StateManagement.bloc,
        architecture: const ArchitectureConfig(
          preset: ArchitecturePreset.blocCentric,
        ),
      );

      expect(
        File(
          '${project.path}/lib/features/orders/data/datasources/orders_remote_data_source.dart',
        ).existsSync(),
        isTrue,
      );
      expect(
        File('${project.path}/lib/features/orders/presentation/bloc/orders_bloc.dart')
            .existsSync(),
        isTrue,
      );
    });
  });

  group('preset registry', () {
    test('allScaffoldPresets includes Tier 2 and Tier 3', () {
      final all = allScaffoldPresets();
      expect(all, contains(ArchitecturePreset.mvvm));
      expect(all, contains(ArchitecturePreset.redux));
      expect(all, contains(ArchitecturePreset.getxModule));
      expect(all.length, tierOnePresets().length +
          tierTwoPresets().length +
          tierThreePresets().length +
          tierFourPresets().length);
    });

    test('every scaffold preset has full layout support', () {
      for (final preset in allScaffoldPresets()) {
        expect(preset.hasFullLayoutSupport, isTrue);
        expect(preset.effectivePreset, preset);
      }
    });
  });

  group('project bootstrap', () {
    test('redux preset creates lib/store', () async {
      final project = _minimalProject();
      addTearDown(() => project.deleteSync(recursive: true));

      final result = await bootstrapProjectArchitecture(
        projectRoot: project,
        architecture: const ArchitectureConfig(
          preset: ArchitecturePreset.redux,
        ),
      );

      expect(
        result.createdPaths.any((p) => p.startsWith('lib/store')),
        isTrue,
      );
    });

    test('riverpod_first preset creates lib/core/di', () async {
      final project = _minimalProject();
      addTearDown(() => project.deleteSync(recursive: true));

      final result = await bootstrapProjectArchitecture(
        projectRoot: project,
        architecture: const ArchitectureConfig(
          preset: ArchitecturePreset.riverpodFirst,
        ),
      );

      expect(
        result.createdPaths.any((p) => p.startsWith('lib/core/di')),
        isTrue,
      );
    });
  });

  group('compatibility', () {
    test('getx module warns when state management is not getx', () {
      final warning = architectureCompatibilityWarning(
        preset: ArchitecturePreset.getxModule,
        stateManagement: StateManagement.bloc,
      );
      expect(warning, isNotNull);
      expect(warning!.suggestedStateManagement, StateManagement.getx);
    });
  });
}

Directory _minimalProject() {
  final dir = Directory.systemTemp.createTempSync('rtk_arch_');
  File('${dir.path}/pubspec.yaml').writeAsStringSync('''
name: sample_app
environment:
  sdk: ">=3.0.0 <4.0.0"
''');
  final lib = Directory('${dir.path}/lib')..createSync();
  File('${lib.path}/main.dart').writeAsStringSync('void main() {}');
  return dir;
}
