import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/config.dart';
import 'package:test/test.dart';

void main() {
  test('isFlutterSdkProject accepts pubspec with flutter sdk', () {
    final dir = Directory.systemTemp.createTempSync('rtk_flutter_sdk_');
    File('${dir.path}/pubspec.yaml').writeAsStringSync('''
name: demo
environment:
  sdk: flutter
dependencies:
  flutter:
    sdk: flutter
''');
    addTearDown(() => dir.deleteSync(recursive: true));
    expect(isFlutterSdkProject(dir), isTrue);
  });

  test('isFlutterSdkProject rejects plain dart package', () {
    final dir = Directory.systemTemp.createTempSync('rtk_dart_only_');
    File('${dir.path}/pubspec.yaml').writeAsStringSync('name: demo\n');
    addTearDown(() => dir.deleteSync(recursive: true));
    expect(isFlutterSdkProject(dir), isFalse);
  });
}
