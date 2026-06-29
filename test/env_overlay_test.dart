import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/env/env_overlay.dart';
import 'package:flutter_project_setup_toolkit/src/env/env_security.dart';
import 'package:flutter_project_setup_toolkit/src/env/env_source.dart';
import 'package:test/test.dart';

void main() {
  test('redactEnvLine hides secrets', () {
    expect(
      redactEnvLine('API_KEY=supersecret'),
      'API_KEY=***',
    );
    expect(
      redactEnvLine('APP_VERSION_NAME=1.0.0'),
      'APP_VERSION_NAME=1.0.0',
    );
  });

  test('session overlay writes and cleans up', () {
    final writer = EnvOverlayWriter(
      root: '${Directory.systemTemp.path}/fpst_test_sessions',
    );
    final overlay = writer.writeSessionOverlay(
      values: {
        'APP_VERSION_NAME': '1.0.0',
        'API_KEY': 'secret',
      },
    );
    expect(overlay.file.existsSync(), isTrue);
    expect(overlay.file.readAsStringSync(), contains('API_KEY=secret'));
    overlay.cleanup();
    expect(overlay.file.existsSync(), isFalse);
  });

  test('resolveBuildEnv uses overlay when project env missing', () {
    final dir = Directory.systemTemp.createTempSync('fpst_env_test_');
    try {
      File('${dir.path}/pubspec.yaml').writeAsStringSync('''
name: demo
environment:
  sdk: ">=3.5.0 <4.0.0"
''');
      File('${dir.path}/release-toolkit.config.json').writeAsStringSync('''
{
  "environments": { "dev": ".env/dev.env" },
  "default_environment": "dev"
}
''');
      final writer = EnvOverlayWriter(
        root: '${dir.path}/.session-cache',
      );
      final resolved = resolveBuildEnv(
        projectRoot: dir,
        envName: 'dev',
        envSource: EnvSourceRequest.fromJson({
          'mode': 'session_values',
          'values': {'APP_VERSION_NAME': '2.0.0'},
        }),
        writer: writer,
      );
      expect(resolved.usedOverlay, isTrue);
      expect(resolved.file.readAsStringSync(), contains('APP_VERSION_NAME=2.0.0'));
      resolved.dispose();
    } finally {
      dir.deleteSync(recursive: true);
    }
  });

  test('resolveBuildEnvOptional returns null when env missing and no overlay', () {
    final dir = Directory.systemTemp.createTempSync('fpst_env_opt_');
    try {
      File('${dir.path}/pubspec.yaml').writeAsStringSync('''
name: demo
environment:
  sdk: ">=3.5.0 <4.0.0"
''');
      final resolved = resolveBuildEnvOptional(
        projectRoot: dir,
        envName: 'dev',
      );
      expect(resolved, isNull);
    } finally {
      dir.deleteSync(recursive: true);
    }
  });
}
