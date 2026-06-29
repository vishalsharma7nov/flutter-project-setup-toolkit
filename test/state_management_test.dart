import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/feature_scaffold.dart';
import 'package:flutter_project_setup_toolkit/src/models.dart';
import 'package:flutter_project_setup_toolkit/src/state_management.dart';
import 'package:test/test.dart';

void main() {
  test('StateManagement.parse accepts known values', () {
    expect(StateManagement.parse('bloc'), StateManagement.bloc);
    expect(StateManagement.parse('none'), StateManagement.none);
    expect(StateManagement.parse('invalid'), isNull);
  });

  test('featureScaffoldRelativePaths includes bloc only for bloc', () {
    final blocPaths = featureScaffoldRelativePaths('ride_', StateManagement.bloc);
    expect(blocPaths.any((path) => path.contains('/bloc/')), isTrue);

    final nonePaths = featureScaffoldRelativePaths('ride_', StateManagement.none);
    expect(nonePaths.any((path) => path.contains('/bloc/')), isFalse);
  });

  test('applyStateManagementPackages skips none', () async {
    final project = Directory.systemTemp.createTempSync('frt_sm_');
    File('${project.path}/pubspec.yaml').writeAsStringSync('''
name: sample_app
environment:
  sdk: ">=3.5.0 <4.0.0"
''');

    final result = await applyStateManagementPackages(
      project,
      StateManagement.none,
    );
    expect(result.skipped, isTrue);
    project.deleteSync(recursive: true);
  });
}
