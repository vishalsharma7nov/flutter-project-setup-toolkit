import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/architecture/architecture_audit.dart';
import 'package:flutter_project_setup_toolkit/src/architecture/architecture_config.dart';
import 'package:flutter_project_setup_toolkit/src/architecture/architecture_core_modules.dart';
import 'package:flutter_project_setup_toolkit/src/architecture/architecture_detect.dart';
import 'package:flutter_project_setup_toolkit/src/architecture/architecture_preset.dart';
import 'package:flutter_project_setup_toolkit/src/architecture/architecture_scaffold.dart';
import 'package:flutter_project_setup_toolkit/src/architecture/project_bootstrap.dart';
import 'package:flutter_project_setup_toolkit/src/architecture_audit_cli.dart';
import 'package:flutter_project_setup_toolkit/src/models.dart';
import 'package:flutter_project_setup_toolkit/src/setup/setup_arch_api_codec.dart';
import 'package:test/test.dart';

void main() {
  group('core modules bootstrap', () {
    test('creates enabled core module stubs', () async {
      final project = _minimalProject();
      addTearDown(() => project.deleteSync(recursive: true));

      await bootstrapProjectArchitecture(
        projectRoot: project,
        architecture: const ArchitectureConfig(
          coreModules: ArchitectureCoreModulesConfig(
            errors: true,
            logging: true,
            theme: true,
          ),
        ),
      );

      expect(
        File('${project.path}/lib/core/errors/failures.dart').existsSync(),
        isTrue,
      );
      expect(
        File('${project.path}/lib/core/logging/app_logger.dart').existsSync(),
        isTrue,
      );
      expect(
        File('${project.path}/lib/core/theme/app_theme.dart').existsSync(),
        isTrue,
      );
    });
  });

  group('flavor mains', () {
    test('creates main_<env>.dart for each environment', () async {
      final project = _minimalProject();
      addTearDown(() => project.deleteSync(recursive: true));

      await bootstrapProjectArchitecture(
        projectRoot: project,
        architecture: const ArchitectureConfig(
          bootstrap: ArchitectureBootstrapConfig(flavorMains: true),
        ),
        environmentNames: ['dev', 'staging', 'prod'],
      );

      expect(File('${project.path}/lib/main_dev.dart').existsSync(), isTrue);
      expect(
        File('${project.path}/lib/main_staging.dart').existsSync(),
        isTrue,
      );
      expect(File('${project.path}/lib/main_prod.dart').existsSync(), isTrue);
    });
  });

  group('test mirror scaffold', () {
    test('mirrors feature dart files under test/', () async {
      final project = _minimalProject();
      addTearDown(() => project.deleteSync(recursive: true));

      final result = await scaffoldFeature(
        projectRoot: project,
        featureName: 'auth',
        architecture: const ArchitectureConfig(
          bootstrap: ArchitectureBootstrapConfig(scaffoldTestMirror: true),
        ),
        stateManagement: StateManagement.none,
      );

      expect(
        result.createdPaths.any(
          (path) => path.contains('test/lib/features/auth'),
        ),
        isTrue,
      );
      expect(
        File(
          '${project.path}/test/lib/features/auth/presentation/pages/auth_page_test.dart',
        ).existsSync(),
        isTrue,
      );
    });
  });

  group('architecture detect', () {
    test('detects micro_feature from melos and packages', () {
      final project = _minimalProject();
      addTearDown(() => project.deleteSync(recursive: true));

      Directory('${project.path}/packages').createSync();
      File('${project.path}/melos.yaml').writeAsStringSync('name: sample');

      final result = detectArchitectureLayout(project);
      expect(result.suggestedPreset, ArchitecturePreset.microFeature);
      expect(result.confidence, greaterThan(0.4));
    });

    test('detects feature_first_clean from layer folders', () {
      final project = _minimalProject();
      addTearDown(() => project.deleteSync(recursive: true));

      final feature = Directory('${project.path}/lib/features/billing')
        ..createSync(recursive: true);
      Directory('${feature.path}/data').createSync();
      Directory('${feature.path}/domain').createSync();
      Directory('${feature.path}/presentation').createSync();

      final result = detectArchitectureLayout(project);
      expect(result.suggestedPreset, ArchitecturePreset.featureFirstClean);
    });
  });

  group('architecture audit', () {
    test('flags cross-feature data imports in presentation', () {
      final project = _minimalProject();
      addTearDown(() => project.deleteSync(recursive: true));

      final authPresentation = Directory(
        '${project.path}/lib/features/auth/presentation',
      )..createSync(recursive: true);
      File('${authPresentation.path}/auth_screen.dart').writeAsStringSync("""
import 'package:sample_app/features/billing/data/billing_repo.dart';

class AuthScreen {}
""");

      final report = runArchitectureAudit(project);
      expect(
        report.issues.any((issue) => issue.code == 'cross_feature_data_import'),
        isTrue,
      );
    });
  });

  group('setup arch api codec', () {
    test('parses phase 7 bootstrap and core module fields', () {
      final config = architectureConfigFromBody({
        'architecture_preset': 'feature_first_clean',
        'core_modules_errors': true,
        'bootstrap_flavor_mains': true,
        'bootstrap_scaffold_test_mirror': true,
      });

      expect(config.coreModules.errors, isTrue);
      expect(config.bootstrap.flavorMains, isTrue);
      expect(config.bootstrap.scaffoldTestMirror, isTrue);
    });
  });

  group('architecture audit cli', () {
    test('exits 0 for clean project', () async {
      final project = _minimalProject();
      addTearDown(() => project.deleteSync(recursive: true));

      final code = await runArchitectureAuditCli(['--project=${project.path}']);
      expect(code, 0);
    });
  });
}

Directory _minimalProject() {
  final dir = Directory.systemTemp.createTempSync('rtk_phase7_');
  File('${dir.path}/pubspec.yaml').writeAsStringSync('''
name: sample_app
environment:
  sdk: ">=3.0.0 <4.0.0"
''');
  final lib = Directory('${dir.path}/lib')..createSync();
  File('${lib.path}/main.dart').writeAsStringSync('void main() {}');
  return dir;
}
