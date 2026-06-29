import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/feature_scaffold.dart';
import 'package:flutter_project_setup_toolkit/src/models.dart';
import 'package:test/test.dart';

void main() {
  test('featureNameToFilePrefix normalizes names', () {
    expect(featureNameToFilePrefix('ride-history'), 'ride_history_');
    expect(featureNameToFilePrefix('RideHistory'), 'ridehistory_');
    expect(featureNameToFilePrefix('user_profile'), 'user_profile_');
  });

  test('scaffoldFeature creates bloc files when state management is bloc', () async {
    final project = Directory.systemTemp.createTempSync('frt_feature_');
    File('${project.path}/pubspec.yaml').writeAsStringSync('name: sample_app\n');

    final result = await scaffoldFeature(
      projectRoot: project,
      featureName: 'ride_history',
      stateManagement: StateManagement.bloc,
    );

    expect(result.rootPath, 'lib/features/ride_history');
    expect(
      File('${project.path}/lib/features/ride_history/presentation/bloc/ride_history_bloc.dart')
          .existsSync(),
      isTrue,
    );

    project.deleteSync(recursive: true);
  });

  test('scaffoldFeature skips bloc layer when state management is none', () async {
    final project = Directory.systemTemp.createTempSync('frt_feature_none_');
    File('${project.path}/pubspec.yaml').writeAsStringSync('name: sample_app\n');

    await scaffoldFeature(
      projectRoot: project,
      featureName: 'ride_history',
      stateManagement: StateManagement.none,
    );

    expect(
      Directory('${project.path}/lib/features/ride_history/presentation/bloc').existsSync(),
      isFalse,
    );
    expect(
      Directory('${project.path}/lib/features/ride_history/presentation/pages').existsSync(),
      isTrue,
    );

    project.deleteSync(recursive: true);
  });
}
