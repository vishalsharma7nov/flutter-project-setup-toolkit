import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/config.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_project_setup_toolkit/src/models.dart';
import 'package:flutter_project_setup_toolkit/src/setup_wizard.dart';
import 'package:flutter_project_setup_toolkit/src/toolkit_install.dart';
import 'package:test/test.dart';

void main() {
  test('defaultEnvPaths uses dotEnv layout', () {
    final paths = defaultEnvPaths(
      ['dev', 'prod'],
      EnvDirectoryStyle.dotEnv,
      '',
    );
    expect(paths['dev'], '.env/development.env');
    expect(paths['prod'], '.env/production.env');
  });

  test('SetupPlan config json includes default environment', () {
    final dir = Directory.systemTemp.createTempSync('frt_setup_');
    final plan = buildSetupPlanFromAnswers(
      projectRoot: dir,
      envNames: ['dev', 'prod'],
      environments: {
        'dev': '.env/development.env',
        'prod': '.env/production.env',
      },
      defaultEnvironment: 'prod',
      versionKeys: Map<String, String>.from(defaultVersionKeys),
      build: const BuildConfig(),
      mainDartEnvRules: const [],
      toolkitMode: ToolkitInstallMode.devDependency,
      createEnvTemplates: true,
      createScripts: true,
    );
    final json = plan.toConfigJson();
    expect(json['default_environment'], 'prod');
    expect(json['environments'], {
      'dev': '.env/development.env',
      'prod': '.env/production.env',
    });
  });

  test('applySetupPlan creates config env files and scripts', () async {
    final toolkitRoot = detectRunningToolkitRoot();
    expect(toolkitRoot, isNotNull);
    final dir = Directory(
      p.join(
        toolkitRoot!.parent.path,
        'frt_setup_apply_${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    dir.createSync(recursive: true);
    addTearDown(() {
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    });
    File('${dir.path}/pubspec.yaml').writeAsStringSync('''
name: sample_app
environment:
  sdk: ">=3.5.0 <4.0.0"
''');
    final relativePath = posixRelativePath(dir, toolkitRoot);
    final plan = buildSetupPlanNonInteractive(
      projectRoot: dir,
      preset: 'dev-prod',
      envDir: '.env',
      defaultEnvironment: 'dev',
      toolkitPath: relativePath,
    );
    final result = await applySetupPlan(plan);
    expect(result.wroteConfig, isTrue);
    expect(result.createdEnvFiles.length, 2);
    expect(result.createdScripts.length, 7);
    expect(result.toolkitInstall?.applied, isTrue);
    expect(hasFlutterReleaseToolkitDependency(dir), isTrue);
    expect(File('${dir.path}/release-toolkit.config.json').existsSync(), isTrue);
    expect(File('${dir.path}/.env/development.env').existsSync(), isTrue);
    expect(File('${dir.path}/scripts/classify-version-bump.sh').existsSync(), isTrue);
    expect(File('${dir.path}/scripts/toolkit-studio.sh').existsSync(), isTrue);
    expect(File('${dir.path}/scripts/make-feature.sh').existsSync(), isTrue);
  });

  test('resolveToolkitInstallPath prefers explicit toolkit path', () {
    final project = Directory.systemTemp.createTempSync('frt_resolve_');
    final plan = ToolkitInstallPlan(
      projectRoot: project,
      mode: ToolkitInstallMode.devDependency,
      toolkitInstallPath: '../flutter-project-setup-toolkit',
    );
    expect(resolveToolkitInstallPath(plan), '../flutter-project-setup-toolkit');
    project.deleteSync(recursive: true);
  });

  test('SetupPlan copyWith updates environments', () {
    final dir = Directory.systemTemp.createTempSync('frt_copy_');
    final plan = buildSetupPlanFromAnswers(
      projectRoot: dir,
      envNames: ['dev', 'prod'],
      environments: {
        'dev': '.env/development.env',
        'prod': '.e',
      },
      defaultEnvironment: 'dev',
      versionKeys: Map<String, String>.from(defaultVersionKeys),
      build: const BuildConfig(),
      mainDartEnvRules: const [],
      toolkitMode: ToolkitInstallMode.devDependency,
      createEnvTemplates: true,
      createScripts: true,
    );
    final updated = plan.copyWith(
      environments: {
        'dev': '.env/development.env',
        'prod': '.env/production.env',
      },
    );
    expect(updated.environments['prod'], '.env/production.env');
    dir.deleteSync(recursive: true);
  });

  test('updateToolkitInstallResult clears prior toolkit failure', () {
    final result = SetupResult(
      wroteConfig: true,
      createdEnvFiles: const [],
      createdScripts: const [],
      skipped: ['toolkit install failed: Local toolkit not found at ../flutter-project-setup-toolkit'],
      toolkitInstall: ToolkitInstallResult(
        applied: false,
        skipped: false,
        error: 'Local toolkit not found at ../flutter-project-setup-toolkit',
      ),
    );
    final fixed = updateToolkitInstallResult(
      result,
      ToolkitInstallResult(
        applied: true,
        skipped: false,
        detail: 'Using local toolkit at ../../Documents/flutter-project-setup-toolkit',
      ),
    );
    expect(fixed.toolkitInstall?.applied, isTrue);
    expect(
      fixed.skipped.any((item) => item.startsWith('toolkit install failed:')),
      isFalse,
    );
  });
}
