import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/classify.dart';
import 'package:flutter_project_setup_toolkit/src/config.dart';
import 'package:flutter_project_setup_toolkit/src/models.dart';
import 'package:flutter_project_setup_toolkit/src/version_logic.dart';
import 'package:test/test.dart';

void main() {
  test('suggestNextVersion patch', () {
    const current = VersionSnapshot(6, 2, 4, 579);
    final next = suggestNextVersion(current, BumpLevel.patch);
    expect(next.$1, '6.2.5');
    expect(next.$2, 580);
  });

  test('ios build resets when marketing version changes', () {
    const current = VersionSnapshot(3, 2, 2, 4);
    final next = iosVersionValuesForBump(current, BumpLevel.minor);
    expect(next.$1, '3.3.0');
    expect(next.$2, 1);
  });

  test('feat message is minor', () {
    final result = classifyCommit('feat: add screen', '', [], '');
    expect(result.level, BumpLevel.minor);
  });

  test('buildEnvVersionUpdates keeps ios independent', () {
    final dir = Directory.systemTemp.createTempSync('frt_test_');
    try {
      final env = File('${dir.path}/app.env')
        ..writeAsStringSync('''
APP_VERSION_NAME=6.2.3
APP_VERSION_CODE=578
BUNDLE_VERSION=1
BUNDLE_VERSION_STRING=3.2.2
''');
      final config = ToolkitConfig(projectRoot: dir);
      final bump = buildEnvVersionUpdates(BumpLevel.minor, env, dir, config);
      expect(bump.current.android!.pubspec, '6.2.3+578');
      expect(bump.current.ios!.pubspec, '3.2.2+1');
      expect(bump.suggested.android!.pubspec, '6.3.0+579');
      expect(bump.suggested.ios!.pubspec, '3.3.0+1');
    } finally {
      dir.deleteSync(recursive: true);
    }
  });
}
