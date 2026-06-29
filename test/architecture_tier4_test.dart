import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/architecture/architecture_compatibility.dart';
import 'package:flutter_project_setup_toolkit/src/architecture/architecture_config.dart';
import 'package:flutter_project_setup_toolkit/src/architecture/architecture_preset.dart';
import 'package:flutter_project_setup_toolkit/src/architecture/architecture_scaffold.dart';
import 'package:flutter_project_setup_toolkit/src/architecture/custom_architecture_template.dart';
import 'package:flutter_project_setup_toolkit/src/architecture/project_bootstrap.dart';
import 'package:flutter_project_setup_toolkit/src/models.dart';
import 'package:test/test.dart';

void main() {
  group('custom template', () {
    test('substitutes feature variables in paths', () {
      const template = CustomArchitectureTemplate(
        featureBasePathTemplate: 'lib/modules/{{feature}}',
        directories: ['controllers'],
        files: ['controllers/{{prefix}}controller.dart'],
      );
      final resolved = template.resolve(
        featureName: 'ride_history',
        filePrefix: 'ride_history_',
      );
      expect(resolved.featureRoot, 'lib/modules/ride_history');
      expect(resolved.files, ['controllers/ride_history_controller.dart']);
    });

    test('scaffoldFeature creates custom template files', () async {
      final project = _minimalProject();
      addTearDown(() => project.deleteSync(recursive: true));

      final templateFile = File(
        '${project.path}/templates/custom.json',
      );
      templateFile.parent.createSync(recursive: true);
      templateFile.writeAsStringSync('''
{
  "feature_base_path": "lib/custom/{{feature}}",
  "directories": ["ui"],
  "files": ["ui/{{prefix}}screen.dart"]
}
''');

      final result = await scaffoldFeature(
        projectRoot: project,
        featureName: 'auth',
        architecture: const ArchitectureConfig(
          preset: ArchitecturePreset.custom,
          customTemplatePath: 'templates/custom.json',
        ),
      );

      expect(result.rootPath, 'lib/custom/auth');
      expect(
        File('${project.path}/lib/custom/auth/ui/auth_screen.dart').existsSync(),
        isTrue,
      );
    });
  });

  group('micro_feature monorepo', () {
    test('bootstrap creates melos workspace and shell app', () async {
      final project = _minimalProject();
      addTearDown(() => project.deleteSync(recursive: true));

      final result = await bootstrapProjectArchitecture(
        projectRoot: project,
        architecture: const ArchitectureConfig(
          preset: ArchitecturePreset.microFeature,
          bootstrap: ArchitectureBootstrapConfig(melos: true),
        ),
      );

      expect(
        result.createdPaths.any((path) => path == 'melos.yaml'),
        isTrue,
      );
      expect(
        File('${project.path}/apps/shell/lib/main.dart').existsSync(),
        isTrue,
      );
    });

    test('scaffoldFeature creates package under packages/', () async {
      final project = _minimalProject();
      addTearDown(() => project.deleteSync(recursive: true));

      final result = await scaffoldFeature(
        projectRoot: project,
        featureName: 'billing',
        architecture: const ArchitectureConfig(
          preset: ArchitecturePreset.microFeature,
        ),
        stateManagement: StateManagement.none,
      );

      expect(result.rootPath, 'packages/billing');
      expect(
        File('${project.path}/packages/billing/pubspec.yaml').existsSync(),
        isTrue,
      );
      expect(
        File(
          '${project.path}/packages/billing/lib/src/presentation/pages/billing_page.dart',
        ).existsSync(),
        isTrue,
      );
    });
  });

  group('tier 4 registry', () {
    test('allScaffoldPresets includes advanced presets', () {
      expect(allScaffoldPresets(), contains(ArchitecturePreset.microFeature));
      expect(allScaffoldPresets(), contains(ArchitecturePreset.custom));
      expect(tierFourPresets().length, 2);
    });
  });
}

Directory _minimalProject() {
  final dir = Directory.systemTemp.createTempSync('rtk_tier4_');
  File('${dir.path}/pubspec.yaml').writeAsStringSync('''
name: sample_app
environment:
  sdk: ">=3.0.0 <4.0.0"
''');
  final lib = Directory('${dir.path}/lib')..createSync();
  File('${lib.path}/main.dart').writeAsStringSync('void main() {}');
  return dir;
}
