import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/version/version_studio_service.dart';
import 'package:test/test.dart';

void main() {
  test('versionEnvironmentsForProject returns env map keys', () {
    final dir = Directory.systemTemp.createTempSync('rtk_version_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    File('${dir.path}/pubspec.yaml').writeAsStringSync('''
name: test_app
environment:
  sdk: ">=3.0.0 <4.0.0"
''');
    final libDir = Directory('${dir.path}/lib')..createSync();
    File('${libDir.path}/main.dart').writeAsStringSync('void main() {}');
    File('${dir.path}/release-toolkit.config.json').writeAsStringSync('''
{
  "default_environment": "dev",
  "environments": {
    "dev": ".env/dev.env",
    "prod": ".env/prod.env"
  }
}
''');

    final result = versionEnvironmentsForProject(dir);
    expect(result['default_environment'], 'dev');
    expect(result['environments'], {
      'dev': '.env/dev.env',
      'prod': '.env/prod.env',
    });
  });
}
