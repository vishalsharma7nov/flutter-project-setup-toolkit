import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/studio/flutter_project_structure.dart';
import 'package:test/test.dart';

void main() {
  test('analyzeFlutterProjectStructure reports compatible flutter app', () {
    final dir = Directory.systemTemp.createTempSync('rtk_compat_');
    File('${dir.path}/pubspec.yaml').writeAsStringSync('''
name: demo
environment:
  sdk: flutter
dependencies:
  flutter:
    sdk: flutter
''');
    Directory('${dir.path}/lib').createSync();
    File('${dir.path}/lib/main.dart').writeAsStringSync('void main() {}');
    addTearDown(() => dir.deleteSync(recursive: true));

    final analysis = analyzeFlutterProjectStructure(dir);
    expect(analysis.compatible, isTrue);
    expect(analysis.canRepair, isFalse);
    expect(analysis.issues.any((i) => i.contains('Optional:')), isTrue);
  });

  test('analyzeFlutterProjectStructure can repair empty folder', () {
    final dir = Directory.systemTemp.createTempSync('rtk_empty_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final analysis = analyzeFlutterProjectStructure(dir);
    expect(analysis.compatible, isFalse);
    expect(analysis.canRepair, isTrue);
    expect(analysis.missing, contains('pubspec.yaml'));
  });

  test('sanitizePubspecProjectName normalizes names', () {
    expect(sanitizePubspecProjectName('My Cool App'), 'my_cool_app');
    expect(sanitizePubspecProjectName('123app'), 'app_123app');
  });
}
