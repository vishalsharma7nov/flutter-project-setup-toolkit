import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/config_file.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('saveReleaseToolkitConfigPatch merges env and build settings', () async {
    final dir = await Directory.systemTemp.createTemp('rtk_config_');
    addTearDown(() => dir.deleteSync(recursive: true));
    File(p.join(dir.path, 'pubspec.yaml')).writeAsStringSync('name: demo\n');

    saveReleaseToolkitConfigPatch(
      projectRoot: dir,
      patch: {
        'default_environment': 'prod',
        'environments': {
          'dev': '.env/dev.env',
          'prod': '.secrets/prod.env',
        },
        'build': {
          'ios_scheme': 'CustomScheme',
          'ios_flavor': null,
          'android_flavor': 'staging',
        },
      },
    );

    final api = releaseToolkitConfigForApi(dir);
    expect(api['default_environment'], 'prod');
    expect(api['environments']['prod'], '.secrets/prod.env');
    expect(api['build']['ios_scheme'], 'CustomScheme');
    expect(api['build']['android_flavor'], 'staging');
    expect(api['build']['ios_flavor'], isNull);
  });

  test('applyReleaseToolkitConfigPatch clears null flavor keys', () {
    final merged = applyReleaseToolkitConfigPatch(
      {
        'build': {
          'ios_flavor': 'old',
          'ios_scheme': 'Runner',
        },
      },
      {
        'build': {
          'ios_flavor': null,
          'ios_scheme': 'Demo',
        },
      },
    );

    expect((merged['build'] as Map).containsKey('ios_flavor'), isFalse);
    expect(merged['build']['ios_scheme'], 'Demo');
  });
}
